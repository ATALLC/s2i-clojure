
IMAGE_NAME = s2i-clojure

all: build setup

.PHONY: build
build:
	docker build -t $(IMAGE_NAME) .

setup:
	docker login -u `oc whoami` -p `oc whoami -t` 172.30.1.1:5000
	docker tag s2i-clojure 172.30.1.1:5000/$(PROJECT)/s2i-clojure-custom:latest
	docker push 172.30.1.1:5000/$(PROJECT)/s2i-clojure-custom:latest

.PHONY: test
test:
	docker build -t $(IMAGE_NAME)-candidate .
	IMAGE_NAME=$(IMAGE_NAME)-candidate test/run
