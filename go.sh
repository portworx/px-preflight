#!/bin/bash

START_PORT=9001
END_PORT=9022
NODES=$(kubectl get nodes -o wide -l 'px/enabled!=false,!node-role.kubernetes.io/master' --no-headers | awk '{print$6}')

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
  echo waiting for pods
  sleep 1
done
sleep 5
kubectl apply -f scan.yml
sleep 5
kubectl logs -n kube-system -lname=nc --tail=-1 | grep NC:|sort

kubectl delete -f scan.yml
kubectl delete -f nc.yml
kubectl delete cm preflight-config -n kube-system
