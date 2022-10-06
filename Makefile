SHELL := /bin/bash
MKFILE_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: setup-test install-std-regular install-std-rapid install-ap-regular install-ap-rapid cleanup
# ## Self help
# help:
# 	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

setup-test: ##Creates four projects and configures directories to test each variation.
	./asm-test-setup.sh

install-std-regular-manual: ##Installs a GKE standard multi cluster ASM MCP test environment using the REGULAR Channel
	./asm-test-create.sh -p $(PROJECT_REGULAR_STD_MANUAL) -r regular -t std -c manual

install-std-regular-automatic: ##Installs a GKE standard multi cluster ASM MCP test environment using the REGULAR Channel
	./asm-test-create.sh -p $(PROJECT_REGULAR_STD_AUTO) -r regular -t std -c automatic

install-std-rapid-manual: ##Installs a GKE standard multi cluster ASM MCP test environment using the RAPID Channel
	./asm-test-create.sh -p $(PROJECT_RAPID_STD) -r rapid -t std -c manual

install-std-rapid-automatic: ##Installs a GKE standard multi cluster ASM MCP test environment using the RAPID Channel
	./asm-test-create.sh -p $(PROJECT_RAPID_STD) -r rapid -t std -c automatic

install-ap-regular-manual: ##Installs a GKE autopilot multi cluster ASM MCP test environment using the REGULAR Channel
	./asm-test-create.sh -p $(PROJECT_REGULAR_AP) -r regular -t ap -c manual

install-ap-rapid: ##Installs a GKE autopilot multi cluster ASM MCP test environment using the RAPID Channel
	./asm-test-create.sh -p $(PROJECT_ID) -r rapid -t ap -c automatic

cross-cluster-test: ##Tests ASM cross clusters service descovery
	./validate-multi-cluster-mesh.sh

cleanup: ## Delete projects created by setup test
	./project-remove.sh