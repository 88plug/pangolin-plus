.PHONY: build build-pg build-release build-release-arm build-release-amd create-manifests build-arm build-x86 test clean

major_tag := $(shell echo $(tag) | cut -d. -f1)
minor_tag := $(shell echo $(tag) | cut -d. -f1,2)

# OCI label variables
CREATED := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
REVISION := $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")

# Common OCI build args for OSS builds
OCI_ARGS_OSS = --build-arg VERSION=$(tag) \
	--build-arg REVISION=$(REVISION) \
	--build-arg CREATED=$(CREATED) \
	--build-arg IMAGE_TITLE="Pangolin" \
	--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere"

# Common OCI build args for Enterprise builds
OCI_ARGS_EE = --build-arg VERSION=$(tag) \
	--build-arg REVISION=$(REVISION) \
	--build-arg CREATED=$(CREATED) \
	--build-arg LICENSE="Fossorial Commercial" \
	--build-arg IMAGE_TITLE="Pangolin EE" \
	--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere"

.PHONY: build-release build-sqlite build-postgresql build-ee-sqlite build-ee-postgresql

build-release: build-sqlite build-postgresql build-ee-sqlite build-ee-postgresql

build-sqlite:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-release tag=<tag>"; \
		exit 1; \
	fi
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=sqlite \
		$(OCI_ARGS_OSS) \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:latest \
		--tag fosrl/pangolin:$(major_tag) \
		--tag fosrl/pangolin:$(minor_tag) \
		--tag fosrl/pangolin:$(tag) \
		--push .

build-postgresql:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-release tag=<tag>"; \
		exit 1; \
	fi
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=pg \
		$(OCI_ARGS_OSS) \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:postgresql-latest \
		--tag fosrl/pangolin:postgresql-$(major_tag) \
		--tag fosrl/pangolin:postgresql-$(minor_tag) \
		--tag fosrl/pangolin:postgresql-$(tag) \
		--push .

build-ee-sqlite:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-release tag=<tag>"; \
		exit 1; \
	fi
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=sqlite \
		$(OCI_ARGS_EE) \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:ee-latest \
		--tag fosrl/pangolin:ee-$(major_tag) \
		--tag fosrl/pangolin:ee-$(minor_tag) \
		--tag fosrl/pangolin:ee-$(tag) \
		--push .

build-ee-postgresql:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-release tag=<tag>"; \
		exit 1; \
	fi
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=pg \
		$(OCI_ARGS_EE) \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:ee-postgresql-latest \
		--tag fosrl/pangolin:ee-postgresql-$(major_tag) \
		--tag fosrl/pangolin:ee-postgresql-$(minor_tag) \
		--tag fosrl/pangolin:ee-postgresql-$(tag) \
		--push .

build-saas:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-release tag=<tag>"; \
		exit 1; \
	fi
	docker buildx build \
		--build-arg BUILD=saas \
		--build-arg DATABASE=pg \
		--platform linux/arm64 \
		--tag $(AWS_IMAGE):$(tag) \
		--push .

build-release-arm:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-release-arm tag=<tag>"; \
		exit 1; \
	fi
	@MAJOR_TAG=$$(echo $(tag) | cut -d. -f1); \
	MINOR_TAG=$$(echo $(tag) | cut -d. -f1,2); \
	CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64 \
		--tag fosrl/pangolin:latest-arm64 \
		--tag fosrl/pangolin:$$MAJOR_TAG-arm64 \
		--tag fosrl/pangolin:$$MINOR_TAG-arm64 \
		--tag fosrl/pangolin:$(tag)-arm64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=pg \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64 \
		--tag fosrl/pangolin:postgresql-latest-arm64 \
		--tag fosrl/pangolin:postgresql-$$MAJOR_TAG-arm64 \
		--tag fosrl/pangolin:postgresql-$$MINOR_TAG-arm64 \
		--tag fosrl/pangolin:postgresql-$(tag)-arm64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg LICENSE="Fossorial Commercial" \
		--build-arg IMAGE_TITLE="Pangolin EE" \
		--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64 \
		--tag fosrl/pangolin:ee-latest-arm64 \
		--tag fosrl/pangolin:ee-$$MAJOR_TAG-arm64 \
		--tag fosrl/pangolin:ee-$$MINOR_TAG-arm64 \
		--tag fosrl/pangolin:ee-$(tag)-arm64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=pg \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg LICENSE="Fossorial Commercial" \
		--build-arg IMAGE_TITLE="Pangolin EE" \
		--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64 \
		--tag fosrl/pangolin:ee-postgresql-latest-arm64 \
		--tag fosrl/pangolin:ee-postgresql-$$MAJOR_TAG-arm64 \
		--tag fosrl/pangolin:ee-postgresql-$$MINOR_TAG-arm64 \
		--tag fosrl/pangolin:ee-postgresql-$(tag)-arm64 \
		--push .

build-release-amd:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-release-amd tag=<tag>"; \
		exit 1; \
	fi
	@MAJOR_TAG=$$(echo $(tag) | cut -d. -f1); \
	MINOR_TAG=$$(echo $(tag) | cut -d. -f1,2); \
	CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/amd64 \
		--tag fosrl/pangolin:latest-amd64 \
		--tag fosrl/pangolin:$$MAJOR_TAG-amd64 \
		--tag fosrl/pangolin:$$MINOR_TAG-amd64 \
		--tag fosrl/pangolin:$(tag)-amd64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=pg \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/amd64 \
		--tag fosrl/pangolin:postgresql-latest-amd64 \
		--tag fosrl/pangolin:postgresql-$$MAJOR_TAG-amd64 \
		--tag fosrl/pangolin:postgresql-$$MINOR_TAG-amd64 \
		--tag fosrl/pangolin:postgresql-$(tag)-amd64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg LICENSE="Fossorial Commercial" \
		--build-arg IMAGE_TITLE="Pangolin EE" \
		--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/amd64 \
		--tag fosrl/pangolin:ee-latest-amd64 \
		--tag fosrl/pangolin:ee-$$MAJOR_TAG-amd64 \
		--tag fosrl/pangolin:ee-$$MINOR_TAG-amd64 \
		--tag fosrl/pangolin:ee-$(tag)-amd64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=pg \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg LICENSE="Fossorial Commercial" \
		--build-arg IMAGE_TITLE="Pangolin EE" \
		--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/amd64 \
		--tag fosrl/pangolin:ee-postgresql-latest-amd64 \
		--tag fosrl/pangolin:ee-postgresql-$$MAJOR_TAG-amd64 \
		--tag fosrl/pangolin:ee-postgresql-$$MINOR_TAG-amd64 \
		--tag fosrl/pangolin:ee-postgresql-$(tag)-amd64 \
		--push .

create-manifests:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make create-manifests tag=<tag>"; \
		exit 1; \
	fi
	@MAJOR_TAG=$$(echo $(tag) | cut -d. -f1); \
	MINOR_TAG=$$(echo $(tag) | cut -d. -f1,2); \
	echo "Creating multi-arch manifests for sqlite (oss)..." && \
	docker buildx imagetools create \
		--tag fosrl/pangolin:latest \
		--tag fosrl/pangolin:$$MAJOR_TAG \
		--tag fosrl/pangolin:$$MINOR_TAG \
		--tag fosrl/pangolin:$(tag) \
		fosrl/pangolin:latest-arm64 \
		fosrl/pangolin:latest-amd64 && \
	echo "Creating multi-arch manifests for postgresql (oss)..." && \
	docker buildx imagetools create \
		--tag fosrl/pangolin:postgresql-latest \
		--tag fosrl/pangolin:postgresql-$$MAJOR_TAG \
		--tag fosrl/pangolin:postgresql-$$MINOR_TAG \
		--tag fosrl/pangolin:postgresql-$(tag) \
		fosrl/pangolin:postgresql-latest-arm64 \
		fosrl/pangolin:postgresql-latest-amd64 && \
	echo "Creating multi-arch manifests for sqlite (enterprise)..." && \
	docker buildx imagetools create \
		--tag fosrl/pangolin:ee-latest \
		--tag fosrl/pangolin:ee-$$MAJOR_TAG \
		--tag fosrl/pangolin:ee-$$MINOR_TAG \
		--tag fosrl/pangolin:ee-$(tag) \
		fosrl/pangolin:ee-latest-arm64 \
		fosrl/pangolin:ee-latest-amd64 && \
	echo "Creating multi-arch manifests for postgresql (enterprise)..." && \
	docker buildx imagetools create \
		--tag fosrl/pangolin:ee-postgresql-latest \
		--tag fosrl/pangolin:ee-postgresql-$$MAJOR_TAG \
		--tag fosrl/pangolin:ee-postgresql-$$MINOR_TAG \
		--tag fosrl/pangolin:ee-postgresql-$(tag) \
		fosrl/pangolin:ee-postgresql-latest-arm64 \
		fosrl/pangolin:ee-postgresql-latest-amd64 && \
	echo "All multi-arch manifests created successfully!"

build-rc:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-release tag=<tag>"; \
		exit 1; \
	fi
	@CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:$(tag) \
		--push . && \
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=pg \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:postgresql-$(tag) \
		--push . && \
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg LICENSE="Fossorial Commercial" \
		--build-arg IMAGE_TITLE="Pangolin EE" \
		--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:ee-$(tag) \
		--push . && \
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=pg \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg LICENSE="Fossorial Commercial" \
		--build-arg IMAGE_TITLE="Pangolin EE" \
		--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64,linux/amd64 \
		--tag fosrl/pangolin:ee-postgresql-$(tag) \
		--push .

build-rc-arm:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-rc-arm tag=<tag>"; \
		exit 1; \
	fi
	@CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64 \
		--tag fosrl/pangolin:$(tag)-arm64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=pg \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64 \
		--tag fosrl/pangolin:postgresql-$(tag)-arm64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg LICENSE="Fossorial Commercial" \
		--build-arg IMAGE_TITLE="Pangolin EE" \
		--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64 \
		--tag fosrl/pangolin:ee-$(tag)-arm64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=pg \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg LICENSE="Fossorial Commercial" \
		--build-arg IMAGE_TITLE="Pangolin EE" \
		--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64 \
		--tag fosrl/pangolin:ee-postgresql-$(tag)-arm64 \
		--push .

build-rc-amd:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make build-rc-amd tag=<tag>"; \
		exit 1; \
	fi
	@CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/amd64 \
		--tag fosrl/pangolin:$(tag)-amd64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=pg \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/amd64 \
		--tag fosrl/pangolin:postgresql-$(tag)-amd64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg LICENSE="Fossorial Commercial" \
		--build-arg IMAGE_TITLE="Pangolin EE" \
		--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/amd64 \
		--tag fosrl/pangolin:ee-$(tag)-amd64 \
		--push . && \
	docker buildx build \
		--build-arg BUILD=enterprise \
		--build-arg DATABASE=pg \
		--build-arg VERSION=$(tag) \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg LICENSE="Fossorial Commercial" \
		--build-arg IMAGE_TITLE="Pangolin EE" \
		--build-arg IMAGE_DESCRIPTION="Pangolin Enterprise Edition - Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/amd64 \
		--tag fosrl/pangolin:ee-postgresql-$(tag)-amd64 \
		--push .

create-manifests-rc:
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make create-manifests-rc tag=<tag>"; \
		exit 1; \
	fi
	@echo "Creating multi-arch manifests for RC sqlite (oss)..." && \
	docker buildx imagetools create \
		--tag fosrl/pangolin:$(tag) \
		fosrl/pangolin:$(tag)-arm64 \
		fosrl/pangolin:$(tag)-amd64 && \
	echo "Creating multi-arch manifests for RC postgresql (oss)..." && \
	docker buildx imagetools create \
		--tag fosrl/pangolin:postgresql-$(tag) \
		fosrl/pangolin:postgresql-$(tag)-arm64 \
		fosrl/pangolin:postgresql-$(tag)-amd64 && \
	echo "Creating multi-arch manifests for RC sqlite (enterprise)..." && \
	docker buildx imagetools create \
		--tag fosrl/pangolin:ee-$(tag) \
		fosrl/pangolin:ee-$(tag)-arm64 \
		fosrl/pangolin:ee-$(tag)-amd64 && \
	echo "Creating multi-arch manifests for RC postgresql (enterprise)..." && \
	docker buildx imagetools create \
		--tag fosrl/pangolin:ee-postgresql-$(tag) \
		fosrl/pangolin:ee-postgresql-$(tag)-arm64 \
		fosrl/pangolin:ee-postgresql-$(tag)-amd64 && \
	echo "All RC multi-arch manifests created successfully!"

build-arm:
	@CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker buildx build \
		--build-arg VERSION=dev \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/arm64 \
		-t fosrl/pangolin:latest .

build-x86:
	@CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker buildx build \
		--build-arg VERSION=dev \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		--platform linux/amd64 \
		-t fosrl/pangolin:latest .

dev-build-sqlite:
	@CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker build \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=dev \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		-t fosrl/pangolin:latest .

dev-build-pg:
	@CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker build \
		--build-arg DATABASE=pg \
		--build-arg VERSION=dev \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin" \
		--build-arg IMAGE_DESCRIPTION="Identity-aware VPN and proxy for remote access to anything, anywhere" \
		-t fosrl/pangolin:postgresql-latest .

test:
	docker run -it -p 3000:3000 -p 3001:3001 -p 3002:3002 -v ./config:/app/config fosrl/pangolin:latest

clean:
	docker rmi pangolin

# --- pangolin-plus monorepo components ---
#
# Binaries (go build → bin/):  make components-build
# Local Docker images:         make plus-images
# Optional registry push:      make plus-images-push PLUS_REGISTRY=ghcr.io/you/pangolin-plus
#
# badger is a Traefik plugin (Go module), not a long-running image:
#   copy components/badger into Traefik localPlugins, or build with traefik yaegi.
# olm is an end-user client binary (not a controller compose service).

PLUS_REGISTRY ?= pangolin-plus
PLUS_TAG ?= local
# Source tags for retag-on-push (always built by plus-images defaults / compose)
PLUS_LOCAL_REGISTRY ?= pangolin-plus
PLUS_LOCAL_TAG ?= local
# Optional versioned tag: make plus-images VERSION=1.21.1-plus
VERSION ?=
PLUS_BUILD_VERSION = $(if $(VERSION),$(VERSION),$(PLUS_TAG))

.PHONY: components-test components-build \
	newt-test newt-build gerbil-build olm-build badger-test \
	plus-images plus-images-push plus-image-pangolin plus-image-gerbil \
	plus-image-newt plus-image-olm plus-check-vars plus-check-docker

# Shared guards for image tags (empty / unsafe)
define plus-assert-tag-vars
	@if [ -z "$(PLUS_REGISTRY)" ]; then echo "Error: PLUS_REGISTRY is empty"; exit 1; fi
	@if [ -z "$(PLUS_TAG)" ]; then echo "Error: PLUS_TAG is empty"; exit 1; fi
	@case "$(PLUS_REGISTRY)$(PLUS_TAG)$(VERSION)" in \
		*[\'\"\\\;\|\$$\`\ \	]*) echo "Error: PLUS_REGISTRY/PLUS_TAG/VERSION contains unsafe chars"; exit 1;; \
	esac
endef

plus-check-vars:
	$(plus-assert-tag-vars)

plus-check-docker:
	@command -v docker >/dev/null || { echo "Error: docker not found"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "Error: docker daemon not reachable"; exit 1; }

newt-test:
	$(MAKE) -C components/newt test

newt-build:
	@mkdir -p components/newt/bin
	$(MAKE) -C components/newt local
	@echo "→ components/newt/bin/newt"

gerbil-build:
	@mkdir -p components/gerbil/bin
	cd components/gerbil && CGO_ENABLED=0 go build -o bin/gerbil .
	@echo "→ components/gerbil/bin/gerbil"

olm-build:
	@mkdir -p components/olm/bin
	$(MAKE) -C components/olm local
	@echo "→ components/olm/bin/olm"

badger-test:
	cd components/badger && go test ./...

# Local binaries for newt (site), gerbil (edge), olm (user client).
# badger: plugin only — no binary target here (see badger-test).
components-build: newt-build gerbil-build olm-build
	@test -x components/newt/bin/newt
	@test -x components/gerbil/bin/gerbil
	@test -x components/olm/bin/olm
	@echo ""
	@echo "components-build done:"
	@echo "  components/newt/bin/newt"
	@echo "  components/gerbil/bin/gerbil"
	@echo "  components/olm/bin/olm"
	@echo "  badger: Traefik plugin (components/badger) — not a long-running binary"

components-test: newt-test badger-test
	cd components/gerbil && go test ./...
	cd components/olm && go test ./...
	@echo "components-test: newt + gerbil + badger + olm done"

# --- plus Docker images (local load; no multi-arch push) ---
# Tags: $(PLUS_REGISTRY)/{pangolin,gerbil,newt,olm}:$(PLUS_TAG)
# Defaults: pangolin-plus/*:local  (matches compose.plus.yaml)

plus-image-pangolin: plus-check-vars plus-check-docker
	docker build \
		--build-arg BUILD=oss \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION="$(PLUS_BUILD_VERSION)" \
		-t "$(PLUS_REGISTRY)/pangolin:$(PLUS_TAG)" \
		$(if $(VERSION),-t "$(PLUS_REGISTRY)/pangolin:$(VERSION)",) \
		-f Dockerfile .

plus-image-gerbil: plus-check-vars plus-check-docker
	docker build \
		-t "$(PLUS_REGISTRY)/gerbil:$(PLUS_TAG)" \
		$(if $(VERSION),-t "$(PLUS_REGISTRY)/gerbil:$(VERSION)",) \
		-f components/gerbil/Dockerfile components/gerbil

plus-image-newt: plus-check-vars plus-check-docker
	docker build \
		--build-arg VERSION="$(PLUS_BUILD_VERSION)" \
		-t "$(PLUS_REGISTRY)/newt:$(PLUS_TAG)" \
		$(if $(VERSION),-t "$(PLUS_REGISTRY)/newt:$(VERSION)",) \
		-f components/newt/Dockerfile components/newt

plus-image-olm: plus-check-vars plus-check-docker
	docker build \
		--build-arg VERSION="$(PLUS_BUILD_VERSION)" \
		-t "$(PLUS_REGISTRY)/olm:$(PLUS_TAG)" \
		$(if $(VERSION),-t "$(PLUS_REGISTRY)/olm:$(VERSION)",) \
		-f components/olm/Dockerfile components/olm

plus-images: plus-image-pangolin plus-image-gerbil plus-image-newt plus-image-olm
	@docker image inspect \
		"$(PLUS_REGISTRY)/pangolin:$(PLUS_TAG)" \
		"$(PLUS_REGISTRY)/gerbil:$(PLUS_TAG)" \
		"$(PLUS_REGISTRY)/newt:$(PLUS_TAG)" \
		"$(PLUS_REGISTRY)/olm:$(PLUS_TAG)" \
		>/dev/null
	@echo ""
	@echo "plus-images tagged under $(PLUS_REGISTRY)/*:$(PLUS_TAG)"
	@echo "  (badger is a Traefik plugin — use components/badger as localPlugins source)"
	@echo "Compose: docker compose -f compose.plus.yaml up -d"
	@echo "Lab newt:  docker compose -f compose.plus.yaml --profile lab up -d"

# Optional: push to a registry you control. Does NOT default to GHCR.
# Retags from PLUS_LOCAL_REGISTRY/*:PLUS_LOCAL_TAG (default pangolin-plus/*:local)
# when PLUS_REGISTRY/PLUS_TAG differ, so split build/push invocations work:
#   make plus-images
#   make plus-images-push PLUS_REGISTRY=ghcr.io/you/pangolin-plus PLUS_TAG=local
plus-images-push: plus-check-vars plus-check-docker
	@if [ -z "$(PLUS_REGISTRY)" ] || [ "$(PLUS_REGISTRY)" = "pangolin-plus" ]; then \
		echo "Error: set PLUS_REGISTRY to a real registry (e.g. ghcr.io/you/pangolin-plus)"; \
		echo "  make plus-images-push PLUS_REGISTRY=ghcr.io/you/pangolin-plus PLUS_TAG=local"; \
		exit 1; \
	fi
	@case "$(PLUS_REGISTRY)" in \
		fosrl|fosrl/*|docker.io/fosrl|docker.io/fosrl/*) \
			echo "Error: refuse push to upstream fosrl namespace"; exit 1;; \
	esac
	@# Prefer images already tagged for the push dest; else retag from local defaults
	@for name in pangolin gerbil newt olm; do \
		src="$(PLUS_LOCAL_REGISTRY)/$$name:$(PLUS_LOCAL_TAG)"; \
		dst="$(PLUS_REGISTRY)/$$name:$(PLUS_TAG)"; \
		if docker image inspect "$$dst" >/dev/null 2>&1; then \
			: ; \
		elif docker image inspect "$$src" >/dev/null 2>&1; then \
			echo "retag $$src -> $$dst"; \
			docker tag "$$src" "$$dst"; \
		else \
			echo "Error: missing image $$dst (and no $$src to retag from). Run: make plus-images"; \
			exit 1; \
		fi; \
		if [ -n "$(VERSION)" ]; then \
			docker tag "$$dst" "$(PLUS_REGISTRY)/$$name:$(VERSION)"; \
		fi; \
	done
	docker push "$(PLUS_REGISTRY)/pangolin:$(PLUS_TAG)"
	docker push "$(PLUS_REGISTRY)/gerbil:$(PLUS_TAG)"
	docker push "$(PLUS_REGISTRY)/newt:$(PLUS_TAG)"
	docker push "$(PLUS_REGISTRY)/olm:$(PLUS_TAG)"
	@if [ -n "$(VERSION)" ]; then \
		docker push "$(PLUS_REGISTRY)/pangolin:$(VERSION)"; \
		docker push "$(PLUS_REGISTRY)/gerbil:$(VERSION)"; \
		docker push "$(PLUS_REGISTRY)/newt:$(VERSION)"; \
		docker push "$(PLUS_REGISTRY)/olm:$(VERSION)"; \
	fi
	@echo "plus-images-push: pushed $(PLUS_REGISTRY)/*:$(PLUS_TAG)"
