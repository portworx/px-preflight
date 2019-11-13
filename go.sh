#!/bin/bash

START_PORT=9001
END_PORT=9022
NODES=$(kubectl get nodes -o wide -l 'px/enabled!=false,!node-role.kubernetes.io/master' --no-headers | awk '{print$6}')

MIN_CORES=4
MIN_DOCKER=1.13.1
MIN_KERNEL=3.10.0
MIN_RAM=7719
MIN_VAR=2048

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: preflight-config
  namespace: kube-system
data:
  start_port: "$START_PORT"
  end_port: "$END_PORT"
  nodes: "$NODES"
EOF

kubectl apply -f nc.yml
until kubectl get ds nc -n kube-system --no-headers | awk '{if ($2!=$4) exit(1);}'; do
  echo waiting for nc pods
  sleep 1
done
while : ; do
  ready=$(kubectl logs -n kube-system -lname=nc --tail=-1 | grep READY | wc -l)
  echo $ready of $(wc -w <<<$NODES) nodes ready
  [ $ready -eq $(wc -w <<<$NODES) ] && break
  sleep 1
done

kubectl apply -f node.yml
until kubectl get ds node -n kube-system --no-headers | awk '{if ($2!=$4) exit(1);}'; do
  echo waiting for node pods
  sleep 1
done

while : ; do
  done=$(kubectl logs -n kube-system -lname=node --tail=-1 | grep COMPLETE | wc -l)
  echo $done of $(wc -w <<<$NODES) nodes done
  [ $done -eq $(wc -w <<<$NODES) ] && break
  sleep 1
done

cd /var/tmp
kubectl logs -n kube-system -lname=nc --tail=-1 | grep NC: | sed s/NC:// | sort >preflight.nc
for i in SWAP CPU RAM VAR KERNEL DOCKER; do
  kubectl logs -n kube-system -lname=node --tail=-1 | grep $i: | sed s/$i:// | sort >preflight.node.$i
done

kubectl delete cm preflight-config -n kube-system
kubectl delete cm node-script -n kube-system
kubectl delete cm nc-script -n kube-system
kubectl delete ds node -n kube-system
kubectl delete ds nc -n kube-system

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'
echo SUMMARY
echo -------

while IFS=: read host n; do
  if [ $MIN_CORES -gt $n ]; then
    echo -ne $RED
  else
    echo -ne $GREEN
  fi
  echo $host has $n CPUs
done <preflight.node.CPU

MIN_DOCKER=$(sed 's/^\([0-9]*\.[0-9]*\.[0-9]*\)[^0-9].*/\1/; s/\<[0-9]\>/0&/g' <<<$MIN_DOCKER)
while IFS=: read host n; do
  m=$(sed 's/^\([0-9]*\.[0-9]*\.[0-9]*\)[^0-9].*/\1/; s/\<[0-9]\>/0&/g' <<<$n)
  if [ $m \< $MIN_DOCKER ]; then
    echo -ne $RED
  else
    echo -ne $GREEN
  fi
  echo $host is running Docker $n
done <preflight.node.DOCKER

MIN_KERNEL=$(sed 's/^\([0-9]*\.[0-9]*\.[0-9]*\)[^0-9].*/\1/; s/\<[0-9]\>/0&/g' <<<$MIN_KERNEL)
while IFS=: read host n; do
  m=$(sed 's/^\([0-9]*\.[0-9]*\.[0-9]*\)[^0-9].*/\1/; s/\<[0-9]\>/0&/g' <<<$n)
  if [ $m \< $MIN_KERNEL ]; then
    echo -ne $RED
  else
    echo -ne $GREEN
  fi
  echo $host is running kernel $n
done <preflight.node.KERNEL

while IFS=: read host n; do
  if [ $MIN_RAM -gt $n ]; then
    echo -ne $RED
  else
    echo -ne $GREEN
  fi
  echo $host has $n MB RAM
done <preflight.node.RAM

while IFS=: read host n; do
  if [ $n -gt 0 ]; then
    echo -e $RED$host has swap
  else
    echo -e $GREEN$host has no swap
  fi
done <preflight.node.SWAP

while IFS=: read host n; do
  if [ $MIN_VAR -gt $n ]; then
    echo -ne $RED
  else
    echo -ne $GREEN
  fi
  echo $host has $n MB free on /var
done <preflight.node.VAR

for a in $NODES; do
  for b in $(seq $START_PORT $END_PORT); do
    for c in $NODES; do
      echo "$a:$b:$c"
    done
  done
done >/var/tmp/preflight.nc.desired
comm -23 /var/tmp/preflight.nc.desired /var/tmp/preflight.nc | while IFS=: read dest port src; do
  echo -e ${RED}Cannot connect from $src to $dest:$port
done

echo -ne $RESET
