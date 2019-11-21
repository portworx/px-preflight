# What

This will provision some DaemonSets on your Kubernetes cluster, use them to run some basic checks, provision a job to process the output, and then delete everything. Checks include:
 * Kubernetes version
 * CPU cores
 * Docker version
 * Kernel version
 * RAM
 * /var space
 * Network connectivity between all worker nodes in the defined port range
 * Ping latency
 * Block devices
 * Optional TCP checks, eg objectstore, external etcd

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

3. Configure:
```
[root@master-2 ~]# cd px-preflight
[root@master-2 px-preflight]# vi go.sh
```

 * Configure the port range with `START_PORT` and `END_PORT`
 * Verify the `NODES` variable is being populated according to your infrastructure
 * Set `TCP_CHECKS` for any external services that need to be reached from all of the Portworx nodes, for example: external etcd, objectstore
 * The default `MIN` and `MAX` thresholds should be fine for most use-cases

4. Run:
```
[root@master-2 px-preflight]# sh go.sh
configmap/preflight-config created
configmap/nc-script created
daemonset.apps/nc created
pod/nc-hp2hb condition met
pod/nc-p9284 condition met
pod/nc-w4kd8 condition met
configmap/node-script created
daemonset.apps/node created
pod/node-4jw52 condition met
pod/node-bjc4q condition met
pod/node-m48sp condition met
configmap/preflight-output created
configmap/preflight-job-script created
job.batch/preflight-job created
job.batch/preflight-job condition met
configmap "node-script" deleted
configmap "nc-script" deleted
daemonset.apps "node" deleted
daemonset.apps "nc" deleted
configmap "preflight-output" deleted
configmap "preflight-config" deleted
configmap "preflight-job-script" deleted
job.batch "preflight-job" deleted
SUMMARY
-------
PASS: Cluster is running Kubernetes 1.16.3
FAIL: 192.168.102.101 has 2 CPUs
FAIL: 192.168.102.102 has 2 CPUs
FAIL: 192.168.102.103 has 2 CPUs
PASS: 192.168.102.101 is running Docker 1.13.1
PASS: 192.168.102.102 is running Docker 1.13.1
PASS: 192.168.102.103 is running Docker 1.13.1
PASS: 192.168.102.101 is running kernel 3.10.0-957.1.3.el7.x86_64
PASS: 192.168.102.102 is running kernel 3.10.0-957.1.3.el7.x86_64
PASS: 192.168.102.103 is running kernel 3.10.0-957.1.3.el7.x86_64
PASS: 192.168.102.101 has 7719 MB RAM
PASS: 192.168.102.102 has 7719 MB RAM
PASS: 192.168.102.103 has 7719 MB RAM
PASS: 192.168.102.101 has no swap
PASS: 192.168.102.102 has no swap
PASS: 192.168.102.103 has no swap
PASS: 192.168.102.101 has 9245 MB free on /var
PASS: 192.168.102.102 has 9347 MB free on /var
PASS: 192.168.102.103 has 9348 MB free on /var
FAIL: Cannot connect from 192.168.102.101 to 192.168.1.1:2379
FAIL: Cannot connect from 192.168.102.102 to 192.168.1.1:2379
FAIL: Cannot connect from 192.168.102.103 to 192.168.1.1:2379
PASS: Can connect from 192.168.102.101 to 192.168.1.2:2379
PASS: Can connect from 192.168.102.102 to 192.168.1.2:2379
PASS: Can connect from 192.168.102.103 to 192.168.1.2:2379
PASS: Can connect from 192.168.102.101 to 192.168.1.3:2379
PASS: Can connect from 192.168.102.102 to 192.168.1.3:2379
PASS: Can connect from 192.168.102.103 to 192.168.1.3:2379
192.168.102.101 has device nvme1n1 (20 GB) (disk)
192.168.102.102 has device nvme1n1 (20 GB) (disk)
192.168.102.103 has device nvme1n1 (20 GB) (disk)
PASS: Latency from 192.168.102.101 to 192.168.102.102 is 399 μs
PASS: Latency from 192.168.102.101 to 192.168.102.103 is 221 μs
PASS: Latency from 192.168.102.102 to 192.168.102.101 is 1062 μs
PASS: Latency from 192.168.102.102 to 192.168.102.103 is 310 μs
PASS: Latency from 192.168.102.103 to 192.168.102.101 is 260 μs
PASS: Latency from 192.168.102.103 to 192.168.102.102 is 279 μs
FAIL: Cannot connect from 192.168.102.101 to 192.168.102.102 on 9001/TCP
```

# Notes
 * The output is actually colored, red for bad, green for good. Unfortunately this is not possible to show in markdown.
