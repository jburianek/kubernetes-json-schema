VERSIONS := $(shell cat kube-versions)

schema = https://raw.githubusercontent.com/kubernetes/kubernetes/$@/api/openapi-spec/swagger.json
prefix = https://raw.githubusercontent.com/TODO------REPO-GOES-HERE/master/$@/_definitions.json

.PHONY: help kube-versions clean $(VERSIONS)

help:
	@echo Supported targets: help venv clean all $(VERSIONS)

kube-versions:
	git ls-remote --refs https://github.com/kubernetes/kubernetes.git \
		| grep 'refs\/tags\/v' \
		| awk -F 'refs/tags/' '{print $$2}' \
		| grep -v 'alpha\|beta\|dev\|rc\|v0' \
		| sort --version-sort \
		> kube-versions

venv:
	python3 -m venv venv
	. venv/bin/activate; \
		pip install git+https://github.com/jburianek/openapi2jsonschema.git@kube-properties

clean:
	rm -rf venv

all: $(VERSIONS)

$(VERSIONS): venv
	@echo "Building JSON schema for Kubernetes version $@"
	mkdir -p output
	. venv/bin/activate; \
		openapi2jsonschema -o "output/$@-standalone-strict" --kubernetes --stand-alone --strict "$(schema)"; \
		openapi2jsonschema -o "output/$@-standalone" --kubernetes --stand-alone "$(schema)"; \
		openapi2jsonschema -o "output/$@-local" --kubernetes "$(schema)"; \
		openapi2jsonschema -o "output/$@" --kubernetes --prefix "$(prefix)" "$(schema)"