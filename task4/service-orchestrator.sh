#!/bin/bash

# Complete this script to deploy external-service and counter-service in two separate containers
# You will be using the conductor tool that you completed in task 3.

# Creating link to the tool within this directory
ln -s ../task3/conductor.sh conductor.sh
ln -s ../task3/config.sh config.sh

# use the above scripts to accomplish the following actions -

# Logical actions to do:
# 1. Build image for the container
# 2. Run two containers say c1 and c2 which should run in background. Tip: to keep the container running
#    in background you should use a init program that will not interact with the terminal and will not
#    exit. e.g. sleep infinity, tail -f /dev/null
# 3. Copy directory external-service to c1 and counter-service to c2 at appropriate location. You can
#    put these directories in the containers by copying them within ".containers/{c1,c2}/rootfs/" directory
# 4. Configure network such that:
#    4.a: c1 is connected to the internet and c1 has its port 8080 forwarded to port 3000 of the host
#    4.b: c2 is connected to the internet and does not have any port exposed
#    4.c: peer network is setup between c1 and c2
# 5. Get ip address of c2. You should use script to get the ip address. 
#    You can use ip interface configuration within the host to get ip address of c2 or you can 
#    exec any command within c2 to get it's ip address
# 6. Within c2 launch the counter service using exec [path to counter-service directory within c2]/run.sh
# 7. Within c1 launch the external service using exec [path to external-service directory within c1]/run.sh
# 8. Within your host system open/curl the url: http://localhost:3000 to verify output of the service
# 9. On any system which can ping the host system open/curl the url: `http://<host-ip>:3000` to verify
#    output of the service

set -o errexit
set -o nounset
set -x

if [ ! -d ".images/ourdebian" ]; then
    ./conductor.sh build ourdebian
fi

./conductor.sh run ourdebian c1 sleep infinity &>/dev/null &
./conductor.sh run ourdebian c2 sleep infinity &>/dev/null &

sleep 10

C1ROOT="./.containers/c1/rootfs"
C2ROOT="./.containers/c2/rootfs"

cp -a external-service $C1ROOT
cp -a counter-service $C2ROOT

./conductor.sh addnetwork c1 -i -e 8080-3000
./conductor.sh addnetwork c2 -i
./conductor.sh peer c1 c2

IPOUTPUT=$(./conductor.sh exec c2 ip addr show c2-inside)
IPADDR_C2=$(echo "$IPOUTPUT" | grep -E 'inet' | grep -E 'c2-inside' | awk '{print $2}' | cut -d'/' -f1)

./conductor.sh exec c2 -- bash /counter-service/run.sh
./conductor.sh exec c1 -- bash /external-service/run.sh "http://${IPADDR_C2}:8080/"





