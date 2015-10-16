# EaaS support scripts

Before running any of the bwFLA client scripts a corresponding docker container has to be downloaded.
Assuming that client has installed "docker" application (tested against v1.8.1) only image pulling is required, e.g.:

```
docker pull eaas/bwfla:demo-august-15
```

After the operation finishes, client is able to run desired module by executing corresponding script. 
It is possible to run multiple containers (max. 1 per module) with the same public ip. 
However, if IP addresses are identical for one or more containers on the same node, then client needs 
to specify different ports for each such container. E.g.

```
./run-flavor-emucomp.sh --docker eaas/bwfla:demo-august-15 --public-ip-port 1.2.3.4:8080
./run-flavor-imagearchive.sh --docker eaas/bwfla:demo-august-15 --public-ip-port 1.2.3.4:8081 \
    --archive-dir /mnt/data/image-archive 
```

When docker boots-up, the internally running application server will be accessible for the outside world 
via public IP and Port (in the above example '1.2.3.4:8080' and '1.2.3.4:8081' correspondingly)
Docker takes care of temporary setting of 'iptables' rules such that client doesn't need to perform 
mapping of 'host <---> guest' ports (i.e. NAT). Make sure that your Firewall doesn't interfere with 
the rules set-up by Docker application. 

NOTE: In the following, explanation of the two mandatory parameters (`--docker` & `--public-ip-port`) will be omitted.

## EmuComp
Example:
```
./run-flavor-emucomp.sh --docker eaas/bwfla:demo-august-15 --public-ip-port 1.2.3.5:8080
```
This script starts 'emucomp' module, which is responsible for running individual emulators on dedicated compute 
nodes (possibly in a cluster/cloud environment).
As of now emulators supported in the docker are the following: Qemu, SheepShaver, Basilisk, DosBox, Hatari.

## EaaS Gateway
Example:
```
./run-flavor-eaas.sh --public-ip-port 1.2.3.4:8082 --docker eaas/bwfla:demo-august-15 \
    --emucomp 1.2.3.5:8080,4 --emucomp 1.2.3.6:8080,8
```
This module serves as a scheduler/proxy node for individual 'emucomp' modules deployed in the cloud/cluster. 
When starting the module at least one `--emucomp <VALUE>` has to be specified on the command line. Repeat the 
argument if multiple 'emucomp' modules have to be connected to this 'eaas' module.
Value of the arguments is composed of the IP:PORT of the 'emucomp' to be connected and the number of sessions
it should supports (usually set to the node's CPU-count) coming after comma.

## Image-Archive:
Example:
```
./run-flavor-imagearchive.sh --docker eaas/bwfla:demo-august-15 --public-ip-port 1.2.3.4:8081 \
     --archive-dir /mnt/data/image-archive
```
This script run the 'imagearchive' module. It requires the location of the image archive directory as a parameter.
The 'nbd-export' directory should not contain any symbolic links that point to locations outside of the image-archive 
directory (i.e. only relative paths). 
NOTE: This is due to the fact that the image-archive is mounted inside the docker container, which in turn has no access 
to the host's file-system.

## Workflows

Example:
```
./run-flavor-workflows.sh --docker eaas/bwfla:demo-august-15 --public-ip-port 1.2.3.4:8083 
                               --image-archive 1.2.3.5:8080 
                               --eaas-gateway 1.2.3.6:8080 
                               [--object-files test/object-files --base-uri http://object.store/objects/]
                               [--object-metadata test/object-metadata]
                               [--swarchive-incoming test/swarchive/incoming]
                               [--swarchive-storage test/swarchive/storage]
```

This script starts the 'Workflows' module, which represents a reference implementation of bwFLA usage by a client. 
It contains sample preservation workflows which include archival "ingest/access" of digital objects, full disk images, 
any accompanying software/libraries.

`--image-archive` should point to a location of an image-archive, which contains base image of emulated systems, 
their derivatives, etc.

`--eaas-gateway` should point to a location of an EAAS module, which will serve as a main 'facade' for accepting 
and performing emulation tasks by using one or more 'emucomp' modules on dedicated compute-nodes.

`--object-files` should point to a directory containing user-objects that will appear in the 'ingest' workflow. 
The directory should contain objects in the form "OBJECT_NAME/OBJECT_NAME.iso". E.g. 'test/object-files/OBJECT1/OBJECT1.iso'.

`--base-uri` must be specified iff. `--object-files` was specified previously. This argument defines the URL-prefix for 
the location of the objects via which the object can be download through HTTP protocol ('emucomp' module needs to be able to 
download the object to inject it into the environment). 

`--object-metadata` argument is specified the the metadata for ingested objects will be kept permanently on the host 
inside the corresponding directory. This metadata results from the ingest workflow and describes the object's rendering 
environment, which can be tested via 'access' workflow.

`--swarchive-incoming` is specified, then it must point to the location of the directory which contains software subject 
to 'Software Archive' workflow. 

`--swarchive-storage` is specified, then it must point to a directory which will keep the content and the metadata of the 
software ingested by the 'Software Archive' workflow.
