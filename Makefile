DOCKER_REGISTRY = index.docker.io
IMAGE_NAME = slack-exporter
IMAGE_VERSION = latest
IMAGE_ORG = flaccid
IMAGE_TAG = $(DOCKER_REGISTRY)/$(IMAGE_ORG)/$(IMAGE_NAME):$(IMAGE_VERSION)

WORKING_DIR := $(shell pwd)

.DEFAULT_GOAL := build

.PHONY: build

build:: ## builds the go binary
	@go build -o bin/slack_exporter

docker-build:: ## builds the docker image locally
		@echo http_proxy=$(HTTP_PROXY) http_proxy=$(HTTPS_PROXY)
		@docker build --pull \
		--build-arg=http_proxy=$(HTTP_PROXY) \
		--build-arg=https_proxy=$(HTTPS_PROXY) \
		-t $(IMAGE_TAG) $(WORKING_DIR)

docker-release:: docker-build docker-push ## builds and pushes the docker image to the registry

docker-push:: ## pushes the docker image to the registry
		@docker push $(IMAGE_TAG)

docker-run:: ## runs the docker image locally
		@docker run \
		 	-it \
			-p 2112:2112 \
				$(DOCKER_REGISTRY)/$(IMAGE_ORG)/$(IMAGE_NAME):$(IMAGE_VERSION)

docker-run-shell:: ## runs the docker image locally, but with a shell
		@docker run -it $(DOCKER_REGISTRY)/$(IMAGE_ORG)/$(IMAGE_NAME):$(IMAGE_VERSION) /bin/sh

helm-install:: ## installs the application using the local helm chart
		@helm install \
		--namespace slack-exporter \
		-f helm-values.local.yaml \
		slack-exporter charts/slack-exporter

helm-reinstall:: helm-uninstall helm-install ## re-install the chart

helm-uninstall:: ## uninstalls the helm chart
		@helm uninstall \
		--namespace slack-exporter \
		slack-exporter

helm-upgrade: ## upgrades the install helm chart
	@helm upgrade slack-exporter charts/slack-exporter -n slack-exporter

helm-validate:: ## dry run/print out the helm chart
		@helm install \
		--dry-run \
		--debug \
		-f helm-values.local.yaml \
			slack-exporter charts/slack-exporter

# a help target including self-documenting targets (see the awk statement)
define HELP_TEXT
Usage: make [TARGET]... [MAKEVAR1=SOMETHING]...

Available targets:
endef
export HELP_TEXT
help: ## this help target
	@cat .banner
	@echo
	@echo "$$HELP_TEXT"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / \
		{printf "\033[36m%-30s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)
