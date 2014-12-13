Docker Bugzilla
===============

Configure a running Bugzilla system using Docker

## Features

* Running latest Centos
* Preconfigured with initial data and test product
* Running Apache2 and MySQL Community Server 5.6
* Openssh server so you can ssh in to the system to make changes
* Code resides in `/home/bugzilla/devel/htdocs/bugzilla` and can be updated,
  diffed, and branched using standard git commands

## How to install Docker and Fig

### Linux Workstation

1. Visit [Docker][docker] and get docker up and running on your system.

2. Visit [Fig][fig] to install Fig for managing Docker containers.

### OSX Workstation

1. Visit [Docker][docker] and get docker up and running on your system.

2. Visit [Fig][fig] to install Fig for managing multiple related Docker containers.

3. Start boot2docker in a terminal once it is installed. Ensure that you run the 
 export DOCKER_HOST=... lines when prompted:

```bash
$ boot2docker start
$ export DOCKER_HOST=tcp://192.168.59.103:2375
```

### Windows Workstation

Windows based developers will be best served by installing [Vagrant][vagrant] and
relying on a shim VM to run Docker. Follow the instructions in the installer until
you reach the ``vagrant init`` section. Instead of doing ``vagrant init hashicorp/precise32`` do:

```bash
vagrant init ubuntu/trusty64
```
From there resume the install process and finish with:

```bash
vagrant ssh
```

## How to build Bugzilla Docker image

To build a fresh image, just change to the directory containing the checked out
files and run the below command:

```bash
$ fig build
```

## How to start Bugzilla Docker image

To start a new container (or rerun your last container) you simply do:

```bash
$ fig up
```

This will stay in the foreground and you will see the output from `supervisord`. You
can use the `-d` option to run the container in the background.

To stop, start or remove the container that was created from the last run, you can do:

```bash
$ fig stop
$ fig start
$ fig rm
```

## How to access the Bugzilla container

You can point your browser to `http://localhost:8080/bugzilla` to see the the
Bugzilla home page. The Administrator username is `admin@mozilla.bugs` and the
password is `password`. You can use the Administrator account to creat other
users, add products or components, etc.

You can also ssh into the container using `ssh bugzilla@localhost -p2222` command.
The password  is `bugzilla`. You can run multiple containers but you will need
to give each one a different name/hostname as well as non-conflicting ports
numbers for ssh and httpd.

## TODO

* Update `generate_bmo_data.pl` to include more sample products, groups and
settings to more closely match bugzilla.mozilla.org.
* Enable SSL support.
* Enable memcached
