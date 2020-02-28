# jlovick/base-image
## Adapted From lynncyrin/base-image

A personalized and well documented [docker](https://www.docker.com/) dev time base image.

## Usage

```bash
docker-compose building
docker-compose up &
docker exec -it base-image_base-image_1 /bin/bash /usr/local/bin/entrypoint.sh
ssh jlovick@0.0.0.0

```

If you're looking at this repo and thinking "I want this, but slightly different", I encourage you to copy paste this repo and create your own! Personalize your base image like you'd personalize your laptop, or your living room ✨ Make all the changes you want ✨

## Status

High level components added onto an ubuntu base: these can be enabled by editing the file

- [x] python
- [x] golang
- [x] nodejs
- [x] rustlang
- [x] ruby
- [x] crystal


- [x] zsh
- [x] oh-my-zsh
- [x] sshd
- [x] tmux
- [x] vim

## Motivation and Context

sometimes it nice to have a sane + (modern) development environment with the least hassle.
nuff-said
