# What

This will provision some DaemonSets on your Kubernetes cluster, use them to run some basic checks, and then delete them again.

# How

1. Ensure your Kubernetes cluster is up and running:
```
[root@master-2 ~]# kubectl get nodes
NAME       STATUS   ROLES    AGE     VERSION
master-2   Ready    master   5h59m   v1.16.2
node-2-1   Ready    <none>   5h58m   v1.16.2
node-2-2   Ready    <none>   5h58m   v1.16.2
node-2-3   Ready    <none>   5h58m   v1.16.2
```

2. Clone this repo:
```
Cloning into 'px-preflight'...
remote: Enumerating objects: 23, done.
remote: Counting objects: 100% (23/23), done.
remote: Compressing objects: 100% (20/20), done.
remote: Total 23 (delta 8), reused 10 (delta 2), pack-reused 0
Unpacking objects: 100% (23/23), done.
```

3. cd and run:
```
[root@master-2 ~]# cd px-preflight
[root@master-2 px-preflight]# sh go.sh
configmap/preflight-config created
configmap/nc-script created
daemonset.apps/nc created
waiting for nc pods
waiting for nc pods
waiting for nc pods
3 of 3 nodes ready
configmap/node-script created
daemonset.apps/node created
waiting for node pods
waiting for node pods
waiting for node pods
3 of 3 nodes done
configmap "preflight-config" deleted
configmap "node-script" deleted
configmap "nc-script" deleted
daemonset.apps "node" deleted
daemonset.apps "nc" deleted
192.168.102.101 has 2 CPUs
192.168.102.102 has 2 CPUs
192.168.102.103 has 2 CPUs
192.168.102.101 is running Docker 1.13.1
192.168.102.102 is running Docker 1.13.1
192.168.102.103 is running Docker 1.13.1
192.168.102.101 is running kernel 3.10.0-957.1.3.el7.x86_64
192.168.102.102 is running kernel 3.10.0-957.1.3.el7.x86_64
192.168.102.103 is running kernel 3.10.0-957.1.3.el7.x86_64
192.168.102.101 has 7 GB RAM
192.168.102.102 has 7 GB RAM
192.168.102.103 has 7 GB RAM
192.168.102.101 has no swap
192.168.102.102 has no swap
192.168.102.103 has no swap
192.168.102.101 has 9245 MB free on /var
192.168.102.102 has 9347 MB free on /var
192.168.102.103 has 9348 MB free on /var
```