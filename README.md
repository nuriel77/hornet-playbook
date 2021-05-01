# Hornet Playbook - IOTA

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
   * [Overwrite Hornet Config](#overwrite-hornet-config)
   * [Hornet HTTPS](#hornet-https)
   * [Ports](#ports)
     * [Forward Ports](#forward-ports)
   * [Peers](#peers)
     * [nbctl](#nbctl)
   * [Monitoring](#monitoring)
   * [Security](#security)
   * [Troubleshooting](#troubleshooting)
     * [502 Bad Gateway](#502-bad-gateway)
     * [Connection not Private](#connection-not-private)
     * [DB Corruption](#db-corruption)
     * [Logs](#logs)
     * [Rerun Playbook](#rerun-playbook)
     * [Grafana Dashboards Missing](#grafana-dashboards-missing)
   * [Appendix](#appendix)
     * [Install Alongside IRI-Playbook](#install-alongside-iri-playbook)
     * [Private Tangle](#private-tangle)
     * [Related Documentation](docs/)
   * [Known Issues](#known-issues)
   * [Support the Project](#support-the-project)
<!--te-->

## Requirements

Tested on the following operating systems/architectures:

* CentOS 7 and 8 (x86_64)
* Ubuntu 18.04LTS or 20.04LTS (x86_64, aarch64/arm64 for Raspberry)
* Debian 10 "Buster" (x86_64, aarch64/arm64)
* Raspbian 10 (64 bit)

## Recommendations

* RAM: At least 1.5GB RAM, as less than this can result in out-of-memory failures.
* x2 CPUs are recommended

## Installation

You can first download the script to inspect it before running it, or run it directly:

```sh
sudo bash -c "bash <(curl -s https://raw.githubusercontent.com/nuriel77/hornet-playbook/main/fullnode_install.sh)"
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
BRANCH="dev-branch"; GIT_OPTIONS="-b $BRANCH" bash <(curl -s "https://raw.githubusercontent.com/nuriel77/hornet-playbook/$BRANCH/fullnode_install.sh")
```

To update the playbook to use a different hornet tag/version, for example hornet prerelease version `v0.4.0-rc2`:
```sh
ansible-playbook -i inventory site.yml -v -e hornet_version=v0.4.0-rc2 -e overwrite=yes
```
Note that a Hornet prerelease might require changes on the playbook's code.

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
alpine              latest              965ea09ff2eb        7 weeks ago         5.55MB
```

Note that an image consists of a "REPOSITORY" name and a "TAG".

Images with `<node>` are "dangling" images that have been used for building a docker image (you can use `horc` to cleanup unused images).

Delete a certain image using the image's ID. Images can also be referenced by the image's repository:tag as syntax, e.g. `nginx:latest`:
```sh
docker rmi 231d40e811cd
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

Point your browser to your host's IP address or fully qualified domain name, e.g.:
```sh
https://my-node.io
```
Note that if you haven't configured the HTTPS certificate via `horc` you will get a warning about a self-signed certificate being used.

The first time you connect you'll have to entre the username and password you've configured during the installation. **However** there's one more "dashboard" to login to for which you should just use username: `admin` and password: `admin`.

## Overwrite Hornet Config

It is possible to edit `/var/lib/hornet/config.json` manually and restart HORNET to apply the changes. Re-running the playbook will not overwrite your changes by default.

The recommended way to configure the file without having to worry about it getting overwritten is by copying the variables file to a new overwrite file.

Copy the config variables file to a new file:
```sh
cp /opt/hornet-playbook/group_vars/all/hornet-config-file.yml /opt/hornet-playbook/group_vars/all/z-append.yml
```
Edit the `/opt/hornet-playbook/group_vars/all/z-append.yml` as required (using nano, vi or your preferred editor). The variable names are similar to how you'd read the `config.json`. For example `hornet_config_snapshots_local_downloadURLs` corresponds to `snapshots.local.downloadURLs` in `config.json`. If you want to see the actual mapping you can view the template file in `/opt/hornet-playbook/roles/hornet/templates/config.json.j2`.

Then re-run the playbook while tagging the task to update the configuration file. Any variables you have overwritten and modified in `z-append.yml` will be applied and take precedence.
```sh
cd /opt/hornet-playbook && sudo ansible-playbook -i inventory site.yml -v --tags=hornet_config_file -e overwrite=yes
```

## Hornet HTTPS

When you access your node via its IP address you will likely get a warning from the browser about the site not being secure or certificate invalid for the domain. The reason is that a self-signed certificate has been generated for the node during the installation.

Some browsers should allow you to bypass the warning (`advanced` -> `proceed`). Some browsers may not allow this (e.g. Chrome or Brave on Mac).

You can get a domain name to point to your node's IP. In that case you can use `horc` to request a certificate for your domain. Then you'll be able to access the node using that domain name and the certificate will be approved.

**HTTPS Certificate**

Via `horc` (run on the command line) it is possible to request and enable HTTPS certificate for the node.

Note that you must already have a fully qualified domain name A record pointing to your server's IP.

Enabling a certificate will allow you to connect to your node with IOTA's official wallet.

## Ports

Below is a list of ports and URL paths configured by the playbook by default. External communication goes via `nginx` acting as a reverse proxy. The internal ports are not accessible externally.

NAME               | PORT INTERNAL | PORT EXTERNAL | PROTOCOL | URL PATH       | DESCRIPTION
-------------------|---------------|---------------|----------|----------------|-----------------------------
Dashboard          | 8087          | 443           | HTTPS    | /              | Main dashboard
Hornet API         | 14265         | 443           | HTTPS    | /api           | Used for wallet/API calls
Hornet peering     | 15600         | 15600         | TCP      | not applicable | Main peering port
Grafana            | 3000          | 443           | HTTPS    | /grafana       | Grafana monitoring /grafana
Prometheus         | 9090          | 443           | HTTPS    | /prometheus    | Prometheus metrics
Alertmanager       | 9093          | 443           | HTTPS    | /alertmanager  | Alertmanager for prometheus

All the external ports have been made accessible in the firewall. There is no need to configure the firewall on the node.

### Forward Ports

If you are running the node in an internal network/lan you have to forward at least the following ports from the router to the node:

Ports: 80/tcp (for certificate verification/enabling HTTPS), 443/tcp and 15600/tcp

## Peers

By default HORNET has the autopeering enabled. It is also recommended to have one or two static peers. The tool `horc` or `nbctl` can be used to manage static neighbors.

### nbctl

This tool has been created to help managed peers from the command line instead of having to manually edit `peering.json` which is error-prone.

**If you didn't install your node using the playbook** you can still use this tool. It communicates with HORNET's API to add, remove or list peers:

```sh
wget -O /usr/bin/nbctl https://raw.githubusercontent.com/nuriel77/iri-playbook/feat/docker/roles/iri/files/nbctl && chmod +x /usr/bin/nbctl
```

Example of adding a peer:
```sh
nbctl -a -n somepeer.com:12345
```
Remove:
```sh
nbctl -r -n somepeer.com:12345
```

## Monitoring

If you have monitoring enabled you can point your browser to `https://your-ip-or-domain/grafana`. That will open Grafana where some monitoring dashboards are available.

Monitoring applications (e.g. node-exporter, prometheus, etc) and dashboards can be upgraded using the command:
```sh
cd /opt/hornet-playbook && ansible-playbook -i inventory site.yml -v --tags=monitoring_role
```

## Security

Security should not be taken lightly. It is recommended to take several steps to improve how you interact and authenticate with your server.

Please follow [this guide](https://iri-playbook.readthedocs.io/en/master/securityhardening.html), it works for any Linux server.

## Troubleshooting

If something isn't working as expected, try to gather as much data as possible, as this can help someone who is able to help you finding out the cause of the issue.

If anything is wrong related to Hornet, first thing to look at are Hornet's logs. See how to get logs in [Control Hornet](#control-hornet) chapter.

To check if Hornet's API port is listening you can use the command to see if any output:
```sh
sudo lsof -Pni:14265
```
Note that after restarting Hornet it takes it some time to make the port available (e.g. when loading snapshot file).

### 502 Bad Gateway

If you receive this error when trying to browse to the dashboard then:

* nginx (the webserver/proxy) is working properly
* the back-end to which it is trying to connect isn't working properly.

Nginx takes requests from the web and forwards those internally. For example, `https://my-site.io` tells nginx to connect to Hornet's dashboard. If Hornet is inactive (crashed? starting up?) then nginx would be unable to forward your requests to it. Make sure Hornet is working properly, e.g. checking logs: see [Control Hornet](#control-hornet).

### Connection not Private

You will probably get this message when trying to connect to the dashboard using your IP address.

Other messages might claim certificate is invalid for the domain.

You can safely proceed (most browsers allow to bypass the warning). And please read [Hornet HTTPS](#hornet-https)

### DB Corruption

If Hornet wasn't shut down properly there is a good chance that the DB is corrupted and you will have to remove it and start all over again.


### Logs
In the following link you can read more about how to collect logs from your system. Although this documentation is for IRI, the commands are similar (just replace iri with hornet if needed):

https://iri-playbook.readthedocs.io/en/master/troubleshooting.html#troubleshooting

### Rerun Playbook

You can rerun the playbook to fix most issues. Use the tool `horc`, there's an option to rerun the playbook.

If `horc` isn't working, try the following command:

```sh
cd /opt/hornet-playbook && git pull && ansible-playbook -v site.yml -i inventory -e overwrite=yes
```
This command will reset all configuration files but also make a backup of existing ones so you'll be able to restore any previous peers and settings you had.

### Grafana Dashboards Missing

If you've opened Grafana for the first time and don't see any dashboards listed on the upper-left corner (Home) then you might have to restart Grafana. Simply run:

```sh
sudo systemctl restart grafana-server
```

## Appendix

### Hornet Plugins

Some of Hornet's plugins can be enabled and disabled using the `horc` tool via the menu.

Note about the Tangle Monitor plugin: it uses two ports: 4433 and 4434 where the first is for the API and the latter for the webserver/ws.

You can access the Tangle Monitor using `https://[your-server's-address]:4434`. Once your node is fully synced you will start seeing data.

### Install Alongside IRI-Playbook

This has not been tried and basically **discouraged**. It could work if you know exactly what you are doing, i.e. making sure no conflicting ports between the two.

On the otherhand, you could probably run hornet-playbook alongside goshimmer-playbook. However, this has not been tested yet.

### Private Tangle

The Hornet private tangle setup is documented [here](https://github.com/gohornet/hornet/wiki/Tutorials%3A-Private-Tangle)

Before doing anything make sure you've stopped hornet: `sudo systemctl stop hornet`.

Make sure you remove (or backup to another location) `/var/lib/hornet/mainnetdb/*` and `/var/lib/hornet/snapshot/*` to ensure there are no conflicts with a previous database and snapshot.

Next you'll have to edit `/var/lib/hornet/config.json`: make sure you set the values specified in the `coordinator` configuration as shown [here](https://github.com/gohornet/hornet/wiki/Tutorials%3A-Private-Tangle#configuration). Same for `snapshots`, follow the example in the document (`loadType` etc). **Note** that the correct path for the playbook's base directory is `snapshot/` thus you should end up configuring `snapshot/snapshot.csv` in the configuration.

To generate the **merkle tree root** when using docker you need 2 parameters: a. the image name, b. your COO_SEED.

For example below we're using `gohornet/hornet:v0.5.0` as the image with a random COO_SEED:
```sh
docker run --rm -e COO_SEED=QQXBGONJZKHZBZIEVUYTOYTLPGDGAOVYMOGFNSGPELJFNPZMBLDEJZUPAOCVFZ9JNBKVXNDXYCADRXXFO -v /var/lib/hornet/coordinator:/app/coordinator -v /var/lib/hornet/config.json:/app/config.json -v /var/lib/hornet/profiles.json:/app/profiles.json -v /var/lib/hornet/snapshot:/app/snapshot gohornet/hornet:v0.5.0- tool merkle
```

Following HORNET's official tutorial you'll have to add the `merkle tree root` value as the `address` value in the `coordinator` in `/var/lib/hornet/config.json`.

Note that the state file and merkle tree file path are `coordinator/state` and `coordinator/tree`.

The following step is to create the `snapshot.csv`. You should do that in `/var/lib/hornet/snapshot/snapshot.csv` as this is mounted into the HORNET docker container.

Next, here's an example of the coordinator bootstrap command, as before, providing the COO_SEED and the docker image to use:
```sh
docker run --rm -e COO_SEED=QQXBGONJZKHZBZIEVUYTOYTLPGDGAOVYMOGFNSGPELJFNPZMBLDEJZUPAOCVFZ9JNBKVXNDXYCADRXXFO -v /var/lib/hornet/mainnetdb:/app/mainnetdb -v /var/lib/hornet/coordinator:/app/coordinator -v /var/lib/hornet/snapshot:/app/snapshot -v /var/lib/hornet/config.json:/app/config.json -v /var/lib/hornet/profiles.json:/app/profiles.json gohornet/hornet:v0.5.0 --cooBootstrap
```
Bootstrap is ended once you see milestones being issued. At this point you can stop the process with CTRL-c. It will look like this:
```
...
INFO    Coordinator     milestone issued (1): 9AAHNAXNNQJM9HYHEBAKCNVXOLNYYDEJZWHAMLQPKQDEHMZXHYKJGIJSJJGOSZILWAAFZJGBIKHIXPC99
...
```

Last step before starting up HORNET is adding the COO_SEED to `/etc/default/hornet` (or `/etc/sysconfig/hornet` in CentOS):
```
DOCKER_OPTS="-e COO_SEED=QQXBGONJZKHZBZIEVUYTOYTLPGDGAOVYMOGFNSGPELJFNPZMBLDEJZUPAOCVFZ9JNBKVXNDXYCADRXXFO"
```
Now you can start up HORNET using `sudo systemctl start hornet`

## Known Issues

* Due to the rapid development and changes to Hornet, the configuration file can break the existing configuration when upgrading.

## Support the Project

To create, test and maintain this playbook requires many hours of work and resources. This is done wholeheartedly for the IOTA community.


**NOTE** Have not migrated yet to the new network. If you'd like to donate, please visit again soon once I've done migrating. Thank you.

If you liked this project and would like to leave a donation you can use this IOTA address:
```
iota1qpsszw7jnknct8960t80ffxn2hmx8wrrrw69ca3us6u5kt92c2hhj8s7ccf
```

No IOTA? :star: the project is also a way of saying thank you! :sunglasses:
