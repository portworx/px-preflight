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
pod/nc-7vhqq condition met
pod/nc-dp84q condition met
pod/nc-hrt2j condition met
configmap/node-script created
daemonset.apps/node created
pod/node-7fs5d condition met
pod/node-7gb5v condition met
pod/node-fwpmd condition met
configmap/preflight-output created
configmap/preflight-job-script created
job.batch/preflight-job created
job.batch/preflight-job condition met
configmap "node-script" deleted
configmap "nc-script" deleted
daemonset.extensions "node" deleted
daemonset.extensions "nc" deleted
configmap "preflight-output" deleted
configmap "preflight-config" deleted
configmap "preflight-job-script" deleted
job.batch "preflight-job" deleted
SUMMARY
-------
Kubernetes is 1.11.0 (>=1.10.0 required)

-----------------------------------------------------------------------------------------------------------------------------------------
Node             Cores  Docker version  Kernel                      RAM        Swap      /var free  Block devices
-----------------------------------------------------------------------------------------------------------------------------------------
192.168.101.101  2      1.13.1          3.10.0-957.1.3.el7.x86_64   7719MB     Disabled  9261MB     nvme1n1 (20GB) (disk)
192.168.101.102  2      1.13.1          3.10.0-957.1.3.el7.x86_64   7719MB     Disabled  9262MB     nvme1n1 (20GB) (disk)
192.168.101.103  2      1.13.1          3.10.0-957.1.3.el7.x86_64   7719MB     Disabled  9278MB     nvme1n1 (20GB) (disk)
-----------------------------------------------------------------------------------------------------------------------------------------

Cores: >=4 recommended
Docker: >=1.13.1 required
Kernel: >=3.10.0 required
RAM: >=7719MB recommended
Swap must be disabled
/var must have 2048MB free

Some checks above failed

Ping checks passed (maximum latency 10ms)
Cannot connect from 192.168.101.102 to 192.168.101.101:9002/udp
Cannot connect from 192.168.101.103 to 192.168.101.101:9002/udp
Cannot connect from 192.168.101.102 to 192.168.101.101:9022/tcp
Cannot connect from 192.168.101.103 to 192.168.101.101:9022/tcp
```

```
[root@master-1 px-preflight]# sh go.sh
configmap/preflight-config created
configmap/nc-script created
daemonset.apps/nc created
pod/nc-cb4hm condition met
pod/nc-mcbs2 condition met
pod/nc-wmqrz condition met
configmap/node-script created
daemonset.apps/node created
pod/node-4n84q condition met
pod/node-pc8jv condition met
pod/node-qrx9b condition met
configmap/preflight-output created
configmap/preflight-job-script created
job.batch/preflight-job created
job.batch/preflight-job condition met
configmap "node-script" deleted
configmap "nc-script" deleted
daemonset.extensions "node" deleted
daemonset.extensions "nc" deleted
configmap "preflight-output" deleted
configmap "preflight-config" deleted
configmap "preflight-job-script" deleted
job.batch "preflight-job" deleted
SUMMARY
-------
Kubernetes is 1.11.0 (>=1.10.0 required)

-----------------------------------------------------------------------------------------------------------------------------------------
Node             Cores  Docker version  Kernel                      RAM        Swap      /var free  Block devices
-----------------------------------------------------------------------------------------------------------------------------------------
192.168.101.101  4      1.13.1          3.10.0-957.1.3.el7.x86_64   7719MB     Disabled  9260MB     nvme1n1 (20GB) (disk)
192.168.101.102  4      1.13.1          3.10.0-957.1.3.el7.x86_64   7719MB     Disabled  9260MB     nvme1n1 (20GB) (disk)
192.168.101.103  4      1.13.1          3.10.0-957.1.3.el7.x86_64   7719MB     Disabled  9260MB     nvme1n1 (20GB) (disk)
-----------------------------------------------------------------------------------------------------------------------------------------

Cores: >=4 recommended
Docker: >=1.13.1 required
Kernel: >=3.10.0 required
RAM: >=7719MB recommended
Swap must be disabled
/var must have 2048MB free

All checks above passed

Ping checks passed (maximum latency 10ms)
All internal TCP checks passed

Success - please visit https://install.portworx.com/ to generate your spec
```

# Debugging

If the `-d` flag is supplied to `go.sh`, a debug file will be generated at `/var/tmp/preflight.debug`.

# TODO

 * PX module kernel header dependency (Check available host headers & mirrors)
 * Check etcd endpoints
