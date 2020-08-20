[![Build Status](https://secure.travis-ci.org/Cherryblue/seafile-docker.png?branch=master)](http://travis-ci.org/Cherryblue/seafile-docker)

## About

- [Seafile](https://seafile.com) is an open source software to synchronize your data to a self-hosted server, making you independant from a third party

- [Docker](https://docker.com/) is an open source project to pack, ship and run any Linux application in a lighter weight, faster container than a traditional virtual machine.

- [Raspberry PI](https://raspberrypi.org) is a very popular [SBC](https://en.wikipedia.org/wiki/Single-board_computer) widerly available and very cheap

**This repository is a fork of the original seafile docker image, specifically for adding support of the Raspberry PI release and automatic Seaf-Fuse use inside the container.**

If you need more information about the Seafile image and Docker, I encourage you to have a look to the [original image readme](https://github.com/haiwen/seafile-docker).

## Goals

You get a docker image for you favourite selfhosted cloud software.

You get a seaf-fuse enabled image, allowing you to get access inside the container to the hosted files ; the short-term idea is adding a music server in order to automatically stream your personal music synced on seafile.

## Mods

The music server will be added using Docker Mods in a Docker Compose file. This allows for flexibility in the docker spirit, while not modifying too much the original seafile docker image.

I will create the following music server mods :
- mStream
- navidrome
- polaris
- ...

**Keep in mind this is a WIP**

## How-to
### Requirements
Get [Docker](https://www.raspberrypi.org/blog/docker-comes-to-raspberry-pi/), [Docker-Compose](https://docs.docker.com/compose/install/), and [Git](https://git-scm.com/) if you wish to modify my work

### The docker-compose file suggested
This is a modified version of the original docker-compose file created by Seafile Team.

```version: '3.0'
services:
  db:
    image: biarms/mysql:5.7.30-beta-travis
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - MYSQL_ROOT_PASSWORD=db_dev  # Requested, set the root's password of MySQL service.
      - MYSQL_LOG_CONSOLE=true
    volumes:
      - /path/to/database/storage:/var/lib/mysql  # Requested, specifies the path to MySQL data persistent store.
    networks:
      - seafile-net

  memcached:
    image: memcached:1.5.6
    restart: unless-stopped
    entrypoint: memcached -m 256
    networks:
      - seafile-net

  seafile:
    image: tata-corp/seafile-mc:7.1.4-rpi
    restart: unless-stopped
    ports:
      - "8042:80"   # Custom port used if you have a reverse proxy on the same server. Otherwise you can put "80:80"
      #- "443:443"  # If https is enabled, cancel the comment.
    volumes:
      - /path/to/seafile/storagee:/shared   # Requested, specifies the path to Seafile data persistent store.
    environment:
      - DB_HOST=db
      - DB_USER_HOST=db
      - DB_ROOT_PASSWD=db_dev                       # Requested, the value shuold be root's password of MySQL service.
      - TIME_ZONE=Etc/UTC                           # Optional, default is UTC. Should be uncomment and set to your local time zone.
      - SEAFILE_SERVER_HOSTNAME=yourDomain          # Specifies your host name if https is enabled.
      - SEAFILE_ADMIN_EMAIL=yourMail                # Specifies Seafile admin user, default is 'me@example.com'.
      - SEAFILE_ADMIN_PASSWORD=yourOwnSecret        # Specifies Seafile admin password, default is 'asecret'.
      #- SEAFILE_SERVER_LETSENCRYPT=true   # Whether to use https or not.
    networks:
      - seafile-net
    depends_on:
      - db
      - memcached
    cap_add:                                        # Needed for Seaf-Fuse inside the container
      - SYS_ADMIN                                   # For now Docker doesn't allow it any other way
    devices:                                        # For more information see https://github.com/docker/for-linux/issues/321
      - "/dev/fuse:/dev/fuse"

networks:
  seafile-net:
```

### Troubleshooting

You can run docker commands like "docker logs" or "docker exec" to find errors.

```sh
docker logs -f seafile
# or
docker exec -it seafile bash
```
