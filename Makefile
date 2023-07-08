tag := jobe
name := ujobe

pwd := $(shell pwd)

ifdef DEV
  MOUNT := --mount type=bind,source=$(pwd)/jars,target=/usr/local/lib/java
else
  MOUNT :=
endif

test:
	echo $(MOUNT)

build:
	docker build . -t $(tag)

run:
	docker run $(MOUNT) -d -p 4000:80 $(tag)

relaunch:
	docker stop $(name) && docker rm $(name) && $(MAKE) build run


clean_docker:
	docker image prune -f
	docker container prune -f
