#!/bin/bash
# set -x

USAGE='MAKE SURE TO USE CORRECT COMMAND-LINE (SET MANDATORY ARGS IN SPECIFIED FORMAT)
./run-flavor-eaas.sh --docker <DOCKER>
                     --public-ip-port <PUBLIC_IP:PORT> 
                     --emucomp <IP:PORT>,<NUM_CPUS> ...'

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

        --emucomp)
           EMUCOMPS="$EMUCOMPS $2"
           ;; 

        *) # DEFAULT
            echo "skipping unrecognized option $1"
            ;;
    esac

    shift 2
done

if [ -z "$DOCKER" ] || [ -z "$PUBLIC_IP" ] || [ -z "$PUBLIC_PORT" ] || [ -z "$EMUCOMPS" ]
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

for EMUCOMP in $EMUCOMPS
do
    IFS=',' read -a EMUCOMP_PAIR <<< "$EMUCOMP"
    ENDPOINT="${EMUCOMP_PAIR[0]}"
    CPUS="${EMUCOMP_PAIR[1]}"

    NODES=$NODES"
                  <node>
                    <address>http://$ENDPOINT/emucomp</address>
                    <nodespecs>
                        <cpucores>$CPUS</cpucores>
                        <memory>4096</memory>
                        <disk>100</disk>
                    </nodespecs>
                  </node>
               "

done

CONTAINER="bwFLA-Container_${$}"
docker run --privileged=true -p "$PUBLIC_IP:$PUBLIC_PORT:8080" -d $ATTACHMENT --name "$CONTAINER" --net=bridge -it "$DOCKER" bash
trap releaseContainer EXIT QUIT INT TERM

docker exec -it "$CONTAINER" perl -pe "s#%NODES%#$NODES#g" -i '/home/bwfla/.bwFLA/EaasConf.xml'

docker exec -it "$CONTAINER" sed -r 's#(<modify-wsdl-address>).*(</modify-wsdl-address>)#\1true\2#'                            -i '/home/bwfla/appserver/standalone/configuration/standalone.xml'
docker exec -it "$CONTAINER" sed -r "s#(<wsdl-host>).*(</wsdl-host>)#\1$PUBLIC_IP\2#"                                          -i '/home/bwfla/appserver/standalone/configuration/standalone.xml'
docker exec -it "$CONTAINER" sed -r "/<modify-wsdl-address>.*<\/modify-wsdl-address>/a \\\\t<wsdl-port>$PUBLIC_PORT</wsdl-port>" -i '/home/bwfla/appserver/standalone/configuration/standalone.xml'
docker exec -it "$CONTAINER" bash '/home/bwfla/flavor-start'

echo "FINISHED!"
