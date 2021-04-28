[![Build Status](https://secure.travis-ci.org/Cherryblue/seafile-docker.png?branch=master)](http://travis-ci.org/Cherryblue/seafile-docker)

## About

- [Seafile](https://seafile.com) is an open source software to synchronize your data to a self-hosted server, making you independant from a third party

- [Docker](https://docker.com/) is an open source project to pack, ship and run any Linux application in a lighter weight, faster container than a traditional virtual machine.

- [Raspberry PI](https://raspberrypi.org) is a very popular [SBC](https://en.wikipedia.org/wiki/Single-board_computer) widely available and very cheap

**This repository is a fork of the original seafile docker image, specifically for adding support of the Raspberry PI release and automatic Seaf-Fuse use inside the container.**

If you need more information about the Seafile image and Docker, I encourage you to have a look to the [original image readme](https://github.com/haiwen/seafile-docker).

## Goals

- You get a docker image for your favourite self-hosted cloud software.

- You get a seaf-fuse enabled image, allowing you to get access inside the container to the hosted files

**The short-term goal behind this is to setup a music streamer on your synced music collection. This is already working and some are available below.**

## How-to
### Requirements
Get [Docker](https://www.raspberrypi.org/blog/docker-comes-to-raspberry-pi/), [Docker-Compose](https://docs.docker.com/compose/install/), and [Git](https://git-scm.com/) if you wish to modify my work.

There seems to be a few dependencies for docker-compose : py-pip, python-dev, libffi-dev, openssl-dev, gcc, libc-dev, and make.

### Build
```sudo make server-rpi```

### Pre-build Dockerhub Image
[Get the latest image on DockerHub](https://hub.docker.com/repository/docker/kynn/seafile-rpi)

### The docker-compose file suggested
This is a modified version of the original docker-compose file created by Seafile Team.

```version: '3.8'
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
    image: kynn/seafile-rpi:7.1.4-2020.09.1
    restart: unless-stopped
    ports:
      - "8042:80"   # Custom port used if you have a reverse proxy on the same server. Otherwise you can put "80:80"
      #- "443:443"  # If https is enabled, cancel the comment.
    volumes:
      # See https://stackoverflow.com/questions/53631567/share-a-fuse-fs-mounted-inside-a-docker-container-through-volumes
      - type: bind                                  # This is a specific type of volume mount called Bind-Mount
        bind:                                       # which allows you to submount folders in it,
          propagation: shared                       # from the host side, or from the container side.
        source: /path/to/seafile/storage            # The goal is to submount seafile database in it using seaf-fuse
        target: /shared                             # The seafile image I made will mount the fuse FS in /shared/fuse/mount-point
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

### Mandatory Crontab Root Shell Script for unmounting broken bind-mount
The bind-mount option needed to make fuse work with Docker, and allowing us to share it between containers doesn't unmount and remove itself when docker closes or stops.
You need to do it with admin privilege on your Raspberry PI, using this:
```
#!/bin/sh
# This script is used in conjunction to Docker
# In order to unmount and remove what Docker can't on the host
# When the folder is no longer used (ie Container has stopped or been restarted)
if [ "$#" -ne 1 ]; then
        echo "Exactly one argument must be passed; it must be the folder to unmount and remove"
else
        if [ -d "$1" ]; then
                cmd="ls -l $1"
                $cmd
                status=$?
                if [ "$status" -ne 0 ]; then
                        if echo $status || grep "Transport is not connected"; then
                                umount -l "$1/target"
                                rm -R "$1/target"
                        fi
                fi
        fi
fi
```
This must be executed on /path/to/seafile/storage/**fuse**

I suggest to use it in a root crontab, every minute. Doesn't take much time nor CPU.

### Troubleshooting

You can run docker commands like "docker logs" or "docker exec" to find errors.

```sh
docker logs -f seafile
# or
docker exec -it seafile bash
```
## Setting up a music streaming server
**As said earlier, this seafile is made in order to allow the processing of a music streaming server over your self-hosted data.**
Obviously, only music files are processed by music streaming servers, and only files not encrypted.
**Seafile offers you the possibility to create multiple libraries in which all files will be automatically encrypted. None of these will be seen by the music streaming server.**

From here, you'll be proposed different open-source softwares to add in the proposed Docker-Compose file for music streaming.

### MStream

[MStream](https://mstream.io/) is an excellent music streamer in JS. It has its own android flutter application, and allows you to navigate your collection by folder hierarchy.

In order to set it up, you'll need to add this in the service zone of the precedent Docker-Compose file :
```
  mstream:
    image: linuxserver/mstream
    container_name: mstream
    environment:
      - PUID=1000
      - PGID=1000
      - USER=your_user
      - PASSWORD=your_secret
      - USE_JSON=true/false
      - TZ=Europe/Paris
    volumes:
      - /path/to/mstream:/config
      - type: bind                                  # This is a specific type of volume mount called Bind-Mount
        bind:                                       # which allows you to submount folders in it,
          propagation: shared                       # from the host side, or from the container side.
        source: /path/to/seafile/fuse               # The goal is to submount seafile database in it using seaf-fuse
        target: /music                              # The seafile image I made will mount the fuse FS in /shared/fuse/mount-point
        read_only: true
    ports:
      - 3000:3000
    restart: unless-stopped
    depends_on:
      - seafile
```

### Navidrome

[Navidrome](https://www.navidrome.org/) is written in GO and compatible with AirSonic API, which allows a lot of application to be reused with it. It comes with its own Material UI web interface.

In order to set it up, you'll need to add this in the service zone of the precedent Docker-Compose file :
```
  navidrome:
    image: deluan/navidrome:latest
    restart: unless-stopped
    user: 1000:1000 # should be owner of volumes
    ports:
      - "4533:4533"
    volumes:
      - "/media/d2to/docker/navidrome:/data"
      - type: bind                                  # This is a specific type of volume mount called Bind-Mount
        bind:                                       # which allows you to submount folders in it,
          propagation: shared                       # from the host side, or from the container side.
        source: /path/to/seafile/fuse               # The goal is to submount seafile database in it using seaf-fuse
        target: /music                              # The seafile image I made will mount the fuse FS in /shared/fuse/mount-point
        read_only: true
    depends_on:
      - seafile
```
