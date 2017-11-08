#/bin/bash



set -a # export all variables created next
source $PWD/node.conf
set +a # stop exporting


#echo "MASTER LOCAL: $MASTER_LOCAL"


$MASTER_LOCAL


docker run -d -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302/udp -p 8302:8302 -p 8400:8400 -p 8500:8500  -h $MASTER_NODE progrium/consul --server -bootstrap -ui-dir /ui -advertise=$MASTER_LOCAL

docker run -d -p 4000:4000 swarm manage -H :4000 --replication --advertise $MASTER_LOCAL:4000 consul://$MASTER_LOCAL:8500


sed -i '/#DOCKER_OPTS="/d' /etc/default/docker

sed -i '/Use DOCKER_OPTS/a DOCKER_OPTS=" -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-advertise 0.0.0.0:2375 --cluster-store consul://'"$MASTER_LOCAL"':8500"' /etc/default/docker

sed -i '/ExecStart=/d' /lib/systemd/system/docker.service
sed -i '/EnvironmentFile=/d' /lib/systemd/system/docker.service

sed -i '/for containers run by docker/a ExecStart=/usr/bin/dockerd -H fd:// $DOCKER_OPTS' /lib/systemd/system/docker.service
sed -i '/ExecStart/a EnvironmentFile=-/etc/default/docker' /lib/systemd/system/docker.service

systemctl daemon-reload
systemctl restart docker

#docker start $(docker ps -a -q)

sleep 5

docker run -d --name=registrator -e "constraint:node==$MASTER_NODE" --net=host --volume=/var/run/docker.sock:/tmp/docker.sock registry.nextflow.tech/registrator:latest -tags tags consul://$MASTER_LOCAL:8500 



