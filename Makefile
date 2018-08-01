IMG_NAME ?= opsani/servo-tomcat-wavefront
IMG_TAG ?= latest

container:
	docker build . -t $(IMG_NAME):$(IMG_TAG)

push:
	docker push $(IMG_NAME):$(IMG_TAG)
