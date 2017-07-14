# Setting up StorageOS on a Docker Swarm

This a very basic setup to test StorageOS on Docker Swarm.

## Getting started

Clone this git repo:

```git clone https://github.com/pvdbleek/storageos```

### Deploying consul

```docker stack deploy -c docker-compose.yml storageos-consul```

One one of your swarm nodes, test if consul works properly:

````
curl http://localhost:8500/v1/status/peers
["10.0.1.4:8300","10.0.1.3:8300","10.0.1.5:8300"]
````

This should return three peers in your consul cluster. Do NOT continue if this is not the case. Your storageos will potentially connect to three different kv-stores, and the effects of that are quit funny ;-)

### Install the StorageOS plugin on all swarm nodes

Execute the following on each node: ``` ./setup_storageos_on_dockernode.sh ```

### Verify your installation

````
# export STORAGEOS_USERNAME=storageos STORAGEOS_PASSWORD=storageos
# storageos node ls
NAME                          ADDRESS             HEALTH               SCHEDULER           VOLUMES             TOTAL               USED                VERSION                LABELS
engine1.pvdbleek.dtcntr.net   10.0.21.10          Healthy 40 minutes   true                M: 1, R: 0          19.32 GiB           17.76%              0.7.10 (3fb8936 rev)
engine2.pvdbleek.dtcntr.net   10.0.28.19          Healthy 32 minutes   false               M: 0, R: 0          19.32 GiB           14.95%              0.7.10 (3fb8936 rev)
engine3.pvdbleek.dtcntr.net   10.0.18.252         Healthy 34 minutes   false               M: 0, R: 1          19.32 GiB           16.46%              0.7.10 (3fb8936 rev)
engine4.pvdbleek.dtcntr.net   10.0.19.102         Healthy 34 minutes   false               M: 0, R: 0          19.32 GiB           35.35%              0.7.10 (3fb8936 rev)
engine5.pvdbleek.dtcntr.net   10.0.25.93          Healthy 34 minutes   false               M: 0, R: 1          19.32 GiB           34.71%              0.7.10 (3fb8936 rev)
engine6.pvdbleek.dtcntr.net   10.0.18.53          Healthy 32 minutes   false               M: 0, R: 1          19.32 GiB           34.58%              0.7.10 (3fb8936 rev)
````

## Basic test of StorageOS
I've created a rule to make sure that each volume has three replica's for high-availability:

```storageos rule create --namespace default  --action add --label storageos.feature.replicas=3 replicator```

Now, let's create a docker volume:

```docker volume create --driver storageos --opt size=1 storageos-volume```

Verify that you can see the volume on all swarm nodes:

````
# docker volume ls | grep storageos-volume
storageos:latest    storageos-volume
````

Run a container with that volume and create a file in it:

````
# docker run --rm -ti -v storageos-volume:/data --volume-driver storageos alpine /bin/sh
/ # ls -al /data
total 24
drwxr-xr-x    3 root     root          4096 Jul 14 20:10 .
drwxr-xr-x   26 root     root          4096 Jul 14 20:10 ..
drwx------    2 root     root         16384 Jul 14 19:41 lost+found
/ # touch /data/testfile
/ # ls -al /data
total 24
drwxr-xr-x    3 root     root          4096 Jul 14 20:10 .
drwxr-xr-x   26 root     root          4096 Jul 14 20:10 ..
drwx------    2 root     root         16384 Jul 14 19:41 lost+found
-rw-r--r--    1 root     root             0 Jul 14 20:10 testfile
/ # exit
````
Finally, run the container on another host and verify the content of the volume:

````
# docker run --rm -ti -v storageos-volume:/data --volume-driver storageos alpine /bin/sh
/ # ls -al /data
total 24
drwxr-xr-x    3 root     root          4096 Jul 14 20:10 .
drwxr-xr-x   26 root     root          4096 Jul 14 20:12 ..
drwx------    2 root     root         16384 Jul 14 19:41 lost+found
-rw-r--r--    1 root     root             0 Jul 14 20:10 testfile
/ # exit
````

