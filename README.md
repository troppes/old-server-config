# Old Server Configuration for Reitz.dev

My old server setup from 2020 with docker-compose. Paths are set to `/srv`. \
Please use this only with caution, some docker containers may not be deployed like this anymore.

## Setup Docker
The network traefik needs to be created manually:
``docker network create traefik``

## SYSCTL.conf
In /etc/sysctl.conf add the following lines, if the ELK-Stack is deployed
```
vm.max_map_count=262144
vm.overcommit_memory=1
```