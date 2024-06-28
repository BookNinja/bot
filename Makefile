SHELL := /bin/sh
CLOUD_REGION_NAME := $(if $(CLOUD_REGION_NAME),$(CLOUD_REGION_NAME),us-west-2)
CODEARTIFACT_AUTH_TOKEN := $(shell aws --region $(CLOUD_REGION_NAME) codeartifact get-authorization-token \
 	--domain bearing --query authorizationToken --output text)
NODE_ARTIFACT_URL := $(shell aws --region $(CLOUD_REGION_NAME) codeartifact get-repository-endpoint \
	--domain bearing --repository tokyo --format npm --query 'repositoryEndpoint' --output text)
CODE_URL=$(aws codeartifact get-repository-endpoint --domain bearing --repository tokyo --format npm --output=text)
SERVICE_NAME := tokyo-heimdall
ENV := 	$(if $(ENV),$(ENV),)
VERSION := $(if $(VERSION),$(VERSION),)
.PHONY : build clean help install lint unit-test update

login: # @HELP Login in aws code artifact.
login:
	@aws --region $(CLOUD_REGION_NAME) codeartifact login --tool npm --repository tokyo --domain bearing

build: # @HELP Build package.
build:
	@aws --region $(CLOUD_REGION_NAME) codeartifact login --tool npm --repository tokyo --domain bearing
	@npm run build

build-docker:
build-docker:
	docker build -t heimdall --build-arg ARTIFACT_URL=$(NODE_ARTIFACT_URL) --build-arg CODEARTIFACT_AUTH_TOKEN=$(CODEARTIFACT_AUTH_TOKEN) .

clean: # @HELP Clean shared folder directoy.
clean:
	@rm -rf dist .pytest_cache coverage .nyc_output

install: # @HELP Install project dependencies
install:
	@aws --region $(CLOUD_REGION_NAME) codeartifact login --tool npm --repository tokyo --domain bearing
	@npm ci

install_manual:
	npm config set registry=$(NODE_ARTIFACT_URL)
	npm config set //bearing-757917910993.d.codeartifact.us-west-2.amazonaws.com/npm/tokyo/:_authToken=$(CODEARTIFACT_AUTH_TOKEN)
	npm ci

update_manual:
	npm config set registry=$(NODE_ARTIFACT_URL)
	npm config set //bearing-757917910993.d.codeartifact.us-west-2.amazonaws.com/npm/tokyo/:_authToken=$(CODEARTIFACT_AUTH_TOKEN)
	npm update


deploy-ecr:
	aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 757917910993.dkr.ecr.us-west-2.amazonaws.com \
	&& docker buildx build --platform=linux/amd64 --build-arg ARTIFACT_URL="$(NODE_ARTIFACT_URL)" --build-arg CODEARTIFACT_AUTH_TOKEN="$(CODEARTIFACT_AUTH_TOKEN)" -t $(SERVICE_NAME) . \
	&& docker tag $(SERVICE_NAME):latest 757917910993.dkr.ecr.us-west-2.amazonaws.com/$(SERVICE_NAME):$(VERSION) \
	&& docker push 757917910993.dkr.ecr.us-west-2.amazonaws.com/$(SERVICE_NAME):$(VERSION)

deploy-service:
	aws --region $(CLOUD_REGION_NAME) cloudformation deploy --template-file template.yml --stack-name heimdall-$(ENV) --parameter-overrides BearingEnv=$(ENV) Tag=$(VERSION) ServiceName=heimdall-svc --capabilities CAPABILITY_NAMED_IAM

lint: # @HELP Lint with black format tool
lint:
	@npm run lint -- --fix

unit-test: # @HELP run unit test and report coverage.
unit-test:
	@npm run test

update: # @HELP Update project dependencies
update:
	@aws --region $(CLOUD_REGION_NAME) codeartifact login --tool npm --repository tokyo --domain bearing
	@npm update

help: # @HELP Prints this message
help:
	@echo "VARIABLES:" && \
	echo "  SHELL = $(SHELL)" && \
	echo "  CLOUD_REGION_NAME = $(CLOUD_REGION_NAME)" && \
	echo "  DRY_RUN = $(DRY_RUN)" && \
	echo " " && \
	echo "TARGETS:" && \
	grep -E '^.*: *# *@HELP' $(MAKEFILE_LIST)    \
	    | awk '                                   \
	        BEGIN {FS = ": *# *@HELP"};           \
	        { printf "  %-30s %s\n", $$1, $$2 };  \
		'
