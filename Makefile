keys/id_ed25519:
	ssh-keygen -t ed25519 -f keys/id_ed25519 -N '' -C 'nix-docker-builder-client'		

keys/ssh_host_ed25519_key:
	ssh-keygen -t ed25519 -f keys/ssh_host_ed25519_key -N '' -C 'nix-dock-builder-host'

keys: keys/id_ed25519 keys/ssh_host_ed25519_key # generate ssh keys to ssh into builder

.PHONY: image
image: keys # build docker image to be used as builder
	docker build -t nix-docker-builder .

.PHONY: container
container: # start container to be used as builder
	docker run --restart=always --name=nix-docker-builder --detach --init -p 3022:22 nix-docker-builder:latest

all: keys image container
