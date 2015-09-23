#!/bin/bash
#set -x

USAGE='MAKE SURE TO USE CORRECT COMMAND-LINE (SET MANDATORY ARGS, ANY SPECIFIED DIRS MUST EXIST)
./run-flavor --docker <DOCKER>
             --public-ip <PUBLIC_IP>
             --image-archive <IMAGE_ARCHIVE>
             --eaas-gateway <EAAS_GATEWAY>
             [--object-metadata <OBJ_META_DIR>] 
             [--object-files <OBJ_FL_DIR> --base-uri <BASE_URI>]
             [--system-envs <SYS_ENV_DIR>]
             [--swarchive-storage <SWARCHIVE_STORAGE_DIR> --swarchive-incoming <SWARCHIVE_INCOMING_DIR>]'

if [ $(($# % 2)) -ne 0 ]
then
    echo "$USAGE"
    exit 50
fi

while [ $# -gt 1 ]
do
    case $1 in
        --docker)
            DOCKER="$2"
            ;;

        --public-ip)
            PUBLIC_IP="$2"
            ;;

        --image-archive)
            IMAGE_ARCHIVE="$2"
            ;;
        
        --eaas-gateway)
            EAAS_GATEWAY="$2"
            ;;

        --object-metadata)
            OBJ_META_DIR="$(readlink -f $2)"
            ;;

        --object-files)
            OBJ_FL_DIR="$(readlink -f $2)"
            ;;

        --base-uri)
            BASE_URI="$2"
            ;;

        --system-envs)
            SYS_ENV_DIR="$(readlink -f $2)"
            ;;

        --swarchive-storage)
            SWARCHIVE_STORAGE_DIR="$(readlink -f $2)"
            ;;

        --swarchive-incoming)
            SWARCHIVE_INCOMING_DIR="$(readlink -f $2)"
            ;;
 
        *) # DEFAULT
            echo "skipping unrecognized option $1"
            ;;
    esac

    shift 2
done

if [ -z "$DOCKER" ] || [ -z "$PUBLIC_IP" ] || [ -z "$IMAGE_ARCHIVE" ] || [ -z "$EAAS_GATEWAY" ]  
then
    echo -e "$USAGE"
    exit 50
fi

if [ -n "$OBJ_META_DIR" ]
then 
    if [ -d "$OBJ_META_DIR" ]
    then
        ATTACHMENT="$ATTACHMENT -v $OBJ_META_DIR:/home/bwfla/object-metadata"
    else
        echo -e "$USAGE" 
        exit 51
    fi
fi

if [ -n "$OBJ_FL_DIR" ]
then
    if [ -d "$OBJ_FL_DIR" ]
    then
        ATTACHMENT="$ATTACHMENT -v $OBJ_FL_DIR:/home/bwfla/user-objects"
    else
        echo -e "$USAGE" 
        exit 52
    fi
fi

if ( [ -n "$BASE_URI" ] && [ -z "$OBJ_FL_DIR" ] ) || ( [ -z "$BASE_URI" ] && [ -n "$OBJ_FL_DIR" ] )
then
    echo -e "$USAGE"
    exit 53
fi

if [ -n "$SYS_ENV_DIR" ]
then 
    if [ -d "$SYS_ENV_DIR" ]
    then
        ATTACHMENT="$ATTACHMENT -v $SYS_ENV_DIR:/home/bwfla/system-env"
    else
        echo -e "$USAGE"
        exit 54
    fi
fi

if [ -n "$SWARCHIVE_STORAGE_DIR" ]
then
    if [ -d "$SWARCHIVE_STORAGE_DIR" ] 
    then
        ATTACHMENT="$ATTACHMENT -v $SWARCHIVE_STORAGE_DIR:/home/bwfla/software-archive/storage"
    else
        echo -e "$USAGE"
        exit 55
    fi
fi

if [ -n "$SWARCHIVE_INCOMING_DIR" ]
then
    if [ -d "$SWARCHIVE_INCOMING_DIR" ]
    then
        ATTACHMENT="$ATTACHMENT -v $SWARCHIVE_INCOMING_DIR:/home/bwfla/software-archive/incoming"
    else
        echo -e "$USAGE"
        exit 56
    fi
fi

set -e
releaseContainer()
{
    RET=$?
    set +e

    if [ -n "$CONTAINER" ]
    then
        docker rm -f "$CONTAINER" 1> /dev/null
    fi    

    return $RET
}

CONTAINER='bwFLA-Container'
docker run --privileged=true -d $ATTACHMENT --name "$CONTAINER" --net=host -it "$DOCKER" bash
trap releaseContainer EXIT QUIT INT TERM

docker exec -it "$CONTAINER" sed "s#%IMAGE_ARCHIVE%#$IMAGE_ARCHIVE#g;s#%EAAS_GATEWAY%#$EAAS_GATEWAY#g" -i '/home/bwfla/.bwFLA/WorkflowsConf.xml'
docker exec -it "$CONTAINER" sed "s#%PUBLIC_IP%#$PUBLIC_IP#g" -i '/home/bwfla/.bwFLA/WorkflowsConf.xml' '/home/bwfla/object-archives/user-objects.json' '/home/bwfla/bwfla-start.sh'
docker exec -it "$CONTAINER" sed "s#%BASE_URI%#$BASE_URI#g" -i '/home/bwfla/object-archives/user-objects.json'
docker exec -it "$CONTAINER" '/home/bwfla/bwfla-start.sh'
echo "FINISHED!"
