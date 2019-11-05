#!/bin/bash

START_PORT=9001
END_PORT=9003
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
kubectl apply -f scan.yml

kubectl delete -f scan.yml
kubectl delete -f nc.yml
kubectl delete cm preflight-config -n kube-system
