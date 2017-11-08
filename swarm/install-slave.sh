#/bin/bash

set -a # export all variables created next
source $PWD/node.conf
set +a # stop exporting

echo "Master: $MASTER_LOCAL"
echo "Slave : $SLAVE_LOCAL"

MASTER_IP=$MASTER_LOCAL
SLAVE_IP=$SLAVE_LOCAL


sed -i '/#DOCKER_OPTS="/d' /etc/default/docker 

sed -i '/Use DOCKER_OPTS/a DOCKER_OPTS=" -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-advertise 0.0.0.0:2375 --cluster-store consul://'"$MASTER_LOCAL"':8500"' /etc/default/docker 

sed -i '/ExecStart=/d' /lib/systemd/system/docker.service  

sed -i '/EnvironmentFile=/d' /lib/systemd/system/docker.service 

sed -i '/for containers run by docker/a ExecStart=/usr/bin/dockerd -H fd:// $DOCKER_OPTS' /lib/systemd/system/docker.service 

sed -i '/ExecStart/a EnvironmentFile=-/etc/default/docker' /lib/systemd/system/docker.service 

systemctl daemon-reload 

systemctl restart docker 

docker run -d swarm join --advertise=$SLAVE_LOCAL:2375 consul://$MASTER_LOCAL:8500 

docker run -d -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302 -p 8302:8302/udp -p 8400:8400 -p 8500:8500  -h $SLAVE_NODE -e "constraint:node==$SLAVE_NODE" progrium/consul -ui-dir /ui -join $MASTER_LOCAL -advertise $SLAVE_LOCAL

docker run -d --name=registrator -e "constraint:node==$SLAVE_NODE" --net=host --volume=/var/run/docker.sock:/tmp/docker.sock registry.nextflow.tech/registrator:latest -tags tags consul://$SLAVE_LOCAL:8500 

