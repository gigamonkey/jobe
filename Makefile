name := jobe

build:
	docker build . -t $(name)

run:
	docker run -d -p 4000:80 --name ujobe jobe

clean_docker:
	docker image prune -f
	docker container prune -f
