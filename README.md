# Hornet Playbook (beta) - IOTA

This repository installs a fully operational [IOTA HORNET](https://github.com/gohornet/hornet.git) node.

*Table of contents*

<!--ts-->
   * [Requirements](#requirements)
   * [Recommendations](#recommendations)
   * [Installation](#installation)
     * [For Development](#for-development)
   * [Docker Usage Commands](#docker-usage-commands)
     * [Docker Images](#docker-images)
     * [View Docker Containers](#view-docker-containers)
     * [Hornet Help Output](#hornet-help-output)
   * [Configuration](#configuration)
   * [Control Hornet](#control-hornet)
   * [Hornet Controller App](#hornet-controller-app)
   * [Hornet Dashboard](#hornet-dashboard)
   * [Hornet HTTPS](#hornet-https)
   * [Troubleshooting](#troubleshooting)
     * [502 Bad Gateway](#502-bad-gateway)
     * [DB Corruption](#db-corruption)
     * [Logs](#logs)
   * [Appendix](#appendix)
     * [Install Alongside IRI-Playbook](#install-alongside-iri-playbook)
     * [Related Documentation](docs/)
   * [Known Issues](#known-issues)
   * [Donations](#donations)
<!--te-->

## Requirements

Tested on the following operating systems/architectures:

* CentOS 7 and 8 (x86_64)
* Ubuntu 18.04LTS (x86_64, aarch64/arm64)
* Debian 10 "Buster" (x86_64, aarch64/arm64)

## Recommendations

* RAM: At least 1.5GB RAM, as less than this can result in out-of-memory failures.
* x2 CPUs are recommended

## Installation

Run (as root):
```sh
bash <(curl -s https://raw.githubusercontent.com/nuriel77/hornet-playbook/master/fullnode_install.sh)
```

This pulls the installation file from the root of this repository and executes it.

The installation will:

* Install latest Hornet and start it up.
* Configure basic security (firewalls) and open all required ports for Hornet to operate.
* Install nginx as a reverse proxy to access Hornet's Dashboard.
* Add some helpful tools, e.g.: `horc` and `nbctl`.

### For Development

If you are working on a fork in a feature branch or happen to directly contribute to this repository you can run the installer pointing it to the appropriate branch, e.g.:
```sh
GIT_OPTIONS="-b feature-branch" bash <(curl -s https://raw.githubusercontent.com/nuriel77/hornet-playbook/master/fullnode_install.sh)
```
If you are also working on the `fullnode_install.sh` you maybe have to rename `master` in the URL to the branch name as well, e.g.:
```sh
GIT_OPTIONS="-b feature-branch" bash <(curl -s https://raw.githubusercontent.com/nuriel77/hornet-playbook/feature-branch/fullnode_install.sh)
```

## Docker Usage Commands

These are just a few helpful commands to help you find your way around docker:

### Docker Images

List all images
```sh
docker images
```
The output will look something like:
```sh
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
gohornet/hornet      v0.2.1              c97cba628d38        2 hours ago         90.4MB
<none>              <none>              b7b60a909a8f        2 hours ago         1.01GB
golang              1.13                a1072a078890        8 days ago          803MB
certbot/certbot     latest              3b7ec24cacc3        11 days ago         148MB
nginx               latest              231d40e811cd        3 weeks ago         126MB
haproxy             2.0.8               142dd6fe8afb        7 weeks ago         91.2MB
alpine              latest              965ea09ff2eb        7 weeks ago         5.55MB
```

Note that an image consists of a "REPOSITORY" name and a "TAG".

Images with `<node>` are "dangling" images that have been used for building a docker image (you can use `horc` to cleanup unused images).

Delete a certain image using the image's ID. Images can also be referenced by the image's repository:tag as syntax, e.g. `haproxy:2.0.8`:
```sh
docker rmi b7b60a909a8f
```

## View Docker Containers

View all docker containers:
```sh
docker ps -a
```
## Hornet Help Output
Run hornet with `--help`: given that we know the image's name and the tag. A quick way to get the tag variable configured:
```sh
docker run --rm -it gohornet/hornet:v0.2.1 --help
```

You can get the tag by viewing all images, or check the configuration file to see what is the currently used TAG:

On CentOS:
```sh
grep ^TAG /etc/sysconfig/hornet
```

On Ubuntu/Debian/Raspbian:
```sh
grep ^TAG /etc/default/hornet
```

## Configuration

In the file below we can specify the image and tag to use. In addition we can configure which command line arguments to pass to hornet:

* On Ubuntu/Debian/Raspbian: `/etc/default/hornet`

* On CentOS: `/etc/sysconfig/hornet`

## Control Hornet

Hornet app start:
```sh
systemctl start hornet
```
You can also replace `start` with `stop` or `restart`.

Hornet logs follow:

```sh
journalctl -u hornet -e -f
```
(omit the `-f` for not to follow the logs "live")

## Hornet Controller App

A GUI utility has been added to help manage some basics like controlling the server, viewing logs, upgrading hornet etc.

Make sure you are root (`sudo su`) and run:
```sh
horc
```

## Hornet Dashboard

Point your browser to your host's IP address or fully qualified domain name with port 8081, e.g.:
```sh
https://my-node.io:8081
```

## Hornet HTTPS
A first step is to enable HAProxy via `horc`. By default the API port is not exposed.

The second step is to enable HTTPS certificate. Note that you must already have a fully qualified domain name A record pointing to your server's IP.

Enabling a certificate will allow you to connect to your node with IOTA's official Trinity wallet.

# Troubleshooting

If something isn't working as expected, try to gather as much data as possible, as this can help someone who is able to help you finding out the cause of the issue.

If anything is wrong related to Hornet, first thing to look at are Hornet's logs. See how to get logs in [Control Hornet](#control-hornet) chapter.

To check if Hornet's API port is listening you can use the command to see if any output:
```sh
sudo lsof -Pni:14265
```
Note that after restarting Hornet it takes it some time to make the port available (e.g. when loading snapshot file).

## 502 Bad Gateway

If you receive this error when trying to browse to the dashboard:

* nginx (the webserver/proxy) is working properly
* the back end to which it is trying to connect isn't working properly.

Nginx takes requests from the web and forwards those internally. For example, `https://my-site.io:8081` would tell nginx to connect to Hornet's dashboard. If Hornet is inactive (crashed? starting up?) then nginx would be unable to forward your requests to it. Make sure Hornet is working properly as described in the beginning of this chapter.

## DB Corruption

If Hornet wasn't shut down properly there is a good chance that the DB is corrupted and you will have to remove it and start all over again.


## Logs
In the following link you can read more about how to collect logs from your system. Although this documentation is for IRI, the commands are similar (just replace iri with hornet if needed):

https://iri-playbook.readthedocs.io/en/master/troubleshooting.html#troubleshooting

# Appendix

## Hornet Plugins

Some of Hornet's plugins can be enabled and disabled using the `horc` tool via the menu.

Note about the Tangle Monitor plugin: it uses two ports: 4433 and 4434 where the first is for the API and the latter for the webserver/ws.

You can access the Tangle Monitor using `https://[your-server's-address]:4434`. Once your node is fully synced you will start seeing data.

## Install Alongside IRI-Playbook

This has not been tried and basically **discouraged**. It could work if you know exactly what you are doing, i.e. making sure no conflicting ports between the two.

On the otherhand, you could probably run hornet-playbook alongside goshimmer-playbook. However, this has not been tested yet.

# Known Issues

* Due to the rapid development and changes to Hornet, the configuration file can break the existing configuration when upgrading.

# Donations

If you liked this playbook, and would like to leave a donation you can use this IOTA address:
```
JFYIHZQOPCRSLKIYHTWRSIR9RZELTZKHNZFHGWXAPCQIEBNJSZFIWMSBGAPDKZZGFNTAHBLGNPRRQIZHDFNPQPPWGC
```
