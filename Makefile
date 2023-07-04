tag := jobe
name := ujobe

build:
	docker build . -t $(tag)

run:
	docker run -d -p 4000:80 --name $(name) $(tag)

relaunch:
	docker stop $(name) && docker rm $(name) && $(MAKE) build run



clean_docker:
	docker image prune -f
	docker container prune -f
