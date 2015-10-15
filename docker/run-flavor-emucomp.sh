#!/bin/bash
#set -x

USAGE='MAKE SURE TO USE CORRECT COMMAND-LINE (SET MANDATORY ARGS, ANY SPECIFIED DIRS MUST EXIST)
./run-flavor-emucomp --docker <DOCKER> 
                     --public-ip-port <PUBLIC_IP:PORT>'

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

        --public-ip-port)
            IFS=':' read -a PUBLIC_IP_PORT <<< "$2"
            PUBLIC_IP=${PUBLIC_IP_PORT[0]}
            PUBLIC_PORT=${PUBLIC_IP_PORT[1]}
            ;;
 
        *) # DEFAULT
            echo "skipping unrecognized option $1"
            ;;
    esac

    shift 2
done

if [ -z "$DOCKER" ] || [ -z "$PUBLIC_IP" ] || [ -z "$PUBLIC_PORT" ]
then
    echo -e "$USAGE"
    exit 50
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

CONTAINER="bwFLA-Container_$$"
docker run --privileged=true -p "$PUBLIC_IP:$PUBLIC_PORT:8080" -d $ATTACHMENT --name "$CONTAINER" --net=bridge -it "$DOCKER" bash
trap releaseContainer EXIT QUIT INT TERM

docker exec -it "$CONTAINER" sed -r 's#(<modify-wsdl-address>).*(</modify-wsdl-address>)#\1true\2#'                            -i '/home/bwfla/appserver/standalone/configuration/standalone.xml'
docker exec -it "$CONTAINER" sed -r "s#(<wsdl-host>).*(</wsdl-host>)#\1$PUBLIC_IP\2#"                                          -i '/home/bwfla/appserver/standalone/configuration/standalone.xml'
docker exec -it "$CONTAINER" sed -r "/<modify-wsdl-address>.*<\/modify-wsdl-address>/a \\\\t<wsdl-port>$PUBLIC_PORT</wsdl-port>" -i '/home/bwfla/appserver/standalone/configuration/standalone.xml'
docker exec -it "$CONTAINER" bash '/home/bwfla/flavor-start'

echo "FINISHED!"
