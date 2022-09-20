SHELL := /bin/bash
MKFILE_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: help install-std-regular install-std-rapid install-ap-regular install-ap-rapid
## Self help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install-std-regular: ##Installs a GKE standard multi cluster ASM MCP test environment using the REGULAR Channel
	./asm-test-create.sh -p $(PROJECT_ID) -r regular -t std

install-std-rapid: ##Installs a GKE standard multi cluster ASM MCP test environment using the RAPID Channel
	./asm-test-create.sh -p $(PROJECT_ID) -r rapid -t std

install-ap-regular: ##Installs a GKE autopilot multi cluster ASM MCP test environment using the REGULAR Channel
	./asm-test-create.sh -p $(PROJECT_ID) -r regular -t ap

install-ap-rapid: ##Installs a GKE autopilot multi cluster ASM MCP test environment using the RAPID Channel
	./asm-test-create.sh -p $(PROJECT_ID) -r rapid -t ap

std-cross-cluster-test: ##Tests ASM cross clusters service descovery in standard env
	./cross-cluster-test.sh -t std

ap-cross-cluster-test: ##Tests ASM cross clusters service descovery in autopilot env
	./cross-cluster-test.sh -t ap

