SHELL := /bin/bash
MKFILE_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: setup-test install-std-regular install-std-rapid install-ap-regular install-ap-rapid cleanup
# ## Self help
# help:
# 	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

setup-test: ##Creates four projects and configures directories to test each variation.
	./asm-test-setup.sh

install-std-manual: ##Installs a GKE standard multi cluster ASM MCP test environment using the REGULAR Channel
	./asm-test-create.sh -p $(PROJECT_ID) -r regular -t std -c manual

install-std-regular: ##Installs a GKE standard multi cluster ASM MCP test environment using the REGULAR Channel
	./asm-test-create.sh -p $(PROJECT_ID) -r regular -t std -c automatic

install-std-rapid: ##Installs a GKE standard multi cluster ASM MCP test environment using the RAPID Channel
	./asm-test-create.sh -p $(PROJECT_ID) -r rapid -t std -c automatic

install-ap-regular: ##Installs a GKE autopilot multi cluster ASM MCP test environment using the REGULAR Channel
	./asm-test-create.sh -p $(PROJECT_ID) -r regular -t ap -c automatic

install-ap-rapid: ##Installs a GKE autopilot multi cluster ASM MCP test environment using the RAPID Channel
	./asm-test-create.sh -p $(PROJECT_ID) -r rapid -t ap -c automatic

std-cross-cluster-test: ##Tests ASM cross clusters service descovery in standard env
	./cross-cluster-test.sh -t std

ap-cross-cluster-test: ##Tests ASM cross clusters service descovery in autopilot env
	./cross-cluster-test.sh -t ap

cleanup: ## Delete projects created by setup test
	./project-remove.sh

