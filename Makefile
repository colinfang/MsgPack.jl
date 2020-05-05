DOCKER_IMAGE_NAME=docker.gambit/test-msgpack
DOCKER_TAG=local

.PHONY: test
test: build
	docker run --rm $(DOCKER_IMAGE_NAME):$(DOCKER_TAG)

.PHONY: build
build:
	docker build -t $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) .
