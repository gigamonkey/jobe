# FIXME: tag should really come from git sha or something
tag := jobe
name := ujobe

PLATFORM=linux/amd64

pwd := $(shell pwd)

ifdef DEV
  MOUNT := --mount type=bind,source=$(pwd)/jars,target=/usr/local/lib/java
else
  MOUNT :=
endif

test:
	echo $(MOUNT)

build:
	docker build --platform $(PLATFORM) . -t $(tag)

run:
	docker run --platform $(PLATFORM) --name $(name) $(MOUNT) -d -p 4000:80 $(tag)

relaunch:
	docker stop $(name) && docker rm $(name) && $(MAKE) build run


clean_docker:
	docker image prune -f
	docker container prune -f
