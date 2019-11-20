#!/bin/bash

START_PORT=9001
END_PORT=9022
NODES=$(kubectl get nodes -o wide -l 'px/enabled!=false,!node-role.kubernetes.io/master' --no-headers | awk '{print$6}')

MIN_CORES=4
MIN_DOCKER=1.13.1
MIN_KERNEL=3.10.0
MIN_RAM=7719
MIN_VAR=2048
MAX_PING=10000

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
  min_cores: "$MIN_CORES"
  min_docker: "$MIN_DOCKER"
  min_kernel: "$MIN_KERNEL"
  min_ram: "$MIN_RAM"
  min_var: "$MIN_VAR"
  max_ping: "$MAX_PING"
EOF

kubectl apply -f nc.yml
kubectl wait pod -lname=nc --for=condition=ready -n kube-system
NC_PODS=$(kubectl get pods -lname=nc -n kube-system --no-headers -o custom-columns=NAME:.metadata.name)

kubectl apply -f node.yml
kubectl wait pod -lname=node --for=condition=ready -n kube-system
NODE_PODS=$(kubectl get pods -lname=node -n kube-system --no-headers -o custom-columns=NAME:.metadata.name)
while : ; do
  done=$(for p in $NODE_PODS; do kubectl logs $p -n kube-system --tail=-1; done | grep COMPLETE | wc -l)
  echo $done of $(wc -w <<<$NODES) nodes done
  [ $done -eq $(wc -w <<<$NODES) ] && break
  sleep 1
done

for p in $NC_PODS; do kubectl logs $p -n kube-system --tail=-1; done | grep ^NC: | sort >/var/tmp/preflight
for p in $NODE_PODS; do kubectl logs $p -n kube-system --tail=-1; done | grep ^PF: | sed s/^PF:// | sort >>/var/tmp/preflight
kubectl create cm preflight-output --from-file /var/tmp/preflight -n kube-system

kubectl apply -f job.yml
kubectl wait --for=condition=complete job/preflight-job -n kube-system
JOB_POD=$(kubectl get pods -ljob-name=preflight-job -n kube-system --no-headers -o custom-columns=NAME:.metadata.name)
kubectl logs $JOB_POD -n kube-system --tail=-1 >/var/tmp/preflight

kubectl delete cm node-script -n kube-system
kubectl delete cm nc-script -n kube-system
kubectl delete ds node -n kube-system
kubectl delete ds nc -n kube-system
kubectl delete cm preflight-output -n kube-system
kubectl delete cm preflight-config -n kube-system
kubectl delete cm preflight-job-script -n kube-system
kubectl delete job preflight-job -n kube-system

cat /var/tmp/preflight
rm -f /var/tmp/preflight
