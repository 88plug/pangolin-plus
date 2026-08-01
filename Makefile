.PHONY: build build-pg build-release build-release-arm build-release-amd create-manifests build-arm build-x86 test clean
.PHONY: check-allow-fosrl-tags

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

# ---------------------------------------------------------------------------
# LEGACY upstream-shaped targets (tag + push fosrl/pangolin:*)
# Product path is NOT these targets:
#   local images:  make plus-images
#   published:     make plus-images-push PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus
#   release CI:    .github/workflows/plus-release.yml (tag vX.Y.Z-plus)
# Gated: set ALLOW_FOSRL_TAGS=1 for targets that tag/push fosrl/pangolin
# (build-release*, build-sqlite/ee/rc*, create-manifests*, build-arm/x86).
# Local CI/dev loaders (dev-build-*) use pangolin-plus/* and are NOT gated.
# ---------------------------------------------------------------------------
check-allow-fosrl-tags:
	@if [ "$(ALLOW_FOSRL_TAGS)" != "1" ]; then \
		echo "Error: this target tags fosrl/pangolin:* (upstream-shaped legacy only)."; \
		echo "  Product images:  make plus-images  |  make dev-build-sqlite"; \
		echo "  Published push:  make plus-images-push PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus"; \
		echo "  Release CI:      .github/workflows/plus-release.yml (git tag vX.Y.Z-plus)"; \
		echo "  Force legacy:    ALLOW_FOSRL_TAGS=1 make <target> tag=..."; \
		exit 1; \
	fi

.PHONY: build-release build-sqlite build-postgresql build-ee-sqlite build-ee-postgresql

# Upstream-shaped multi-variant push (fosrl/pangolin:*). Prefer plus-images / plus-release.
build-release: check-allow-fosrl-tags
	$(MAKE) build-sqlite build-postgresql build-ee-sqlite build-ee-postgresql tag=$(tag) ALLOW_FOSRL_TAGS=$(ALLOW_FOSRL_TAGS)

build-sqlite: check-allow-fosrl-tags
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

build-postgresql: check-allow-fosrl-tags
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

build-ee-sqlite: check-allow-fosrl-tags
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

build-ee-postgresql: check-allow-fosrl-tags
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

# Upstream-shaped arm64 push (fosrl/pangolin:*-arm64). Prefer plus-images / plus-release.
build-release-arm: check-allow-fosrl-tags
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

# Upstream-shaped amd64 push (fosrl/pangolin:*-amd64). Prefer plus-images / plus-release.
build-release-amd: check-allow-fosrl-tags
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

# Upstream-shaped multi-arch manifests (fosrl/pangolin:*). Prefer plus-images / plus-release.
create-manifests: check-allow-fosrl-tags
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

build-rc: check-allow-fosrl-tags
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

build-rc-arm: check-allow-fosrl-tags
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

build-rc-amd: check-allow-fosrl-tags
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

create-manifests-rc: check-allow-fosrl-tags
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

build-arm: check-allow-fosrl-tags
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

build-x86: check-allow-fosrl-tags
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

# Local product load only (CI: .github/workflows/test.yml). No fosrl tags, no push.
dev-build-sqlite:
	@CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker build \
		--build-arg DATABASE=sqlite \
		--build-arg VERSION=dev \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin Plus" \
		--build-arg IMAGE_DESCRIPTION="pangolin-plus monorepo local sqlite image" \
		-t pangolin-plus/pangolin:local \
		-t pangolin-plus/pangolin:dev-sqlite .

dev-build-pg:
	@CREATED=$$(date -u +"%Y-%m-%dT%H:%M:%SZ"); \
	REVISION=$$(git rev-parse HEAD 2>/dev/null || echo "unknown"); \
	docker build \
		--build-arg DATABASE=pg \
		--build-arg VERSION=dev \
		--build-arg REVISION=$$REVISION \
		--build-arg CREATED=$$CREATED \
		--build-arg IMAGE_TITLE="Pangolin Plus" \
		--build-arg IMAGE_DESCRIPTION="pangolin-plus monorepo local postgresql image" \
		-t pangolin-plus/pangolin:dev-pg \
		-t pangolin-plus/pangolin:local-pg .

# Local run after dev-build-sqlite (product tags).
test:
	docker run -it -p 3000:3000 -p 3001:3001 -p 3002:3002 -v ./config:/app/config pangolin-plus/pangolin:local

clean:
	-docker rmi pangolin-plus/pangolin:local pangolin-plus/pangolin:dev-sqlite pangolin-plus/pangolin:dev-pg pangolin-plus/pangolin:local-pg 2>/dev/null || true

# --- pangolin-plus monorepo components (PRODUCT PATH) ---
#
# Binaries (go build → bin/):  make components-build
# Local Docker images:         make plus-images
#   → tags $(PLUS_REGISTRY)/{pangolin,gerbil,newt,olm}:$(PLUS_TAG)
#   → default PLUS_REGISTRY=pangolin-plus (local-only name, not a remote registry)
# Published push to GHCR:      make plus-images-push \
#                                PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus \
#                                PLUS_TAG=v1.21.1-plus VERSION=1.21.1-plus
# Multi-OS release binaries:   make plus-release-binaries VERSION=1.21.1-plus
# Product CI:                  .github/workflows/plus-release.yml (tag vX.Y.Z-plus)
#
# Do NOT use legacy build-release* (fosrl/pangolin:*) — see check-allow-fosrl-tags above.
#
# badger is a Traefik plugin (Go module), not a long-running image:
#   copy components/badger into Traefik localPlugins, or build with traefik yaegi.
# olm is an end-user client binary (not a controller compose service).

# Local default (docker tag namespace only). Published path:
#   PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus
PLUS_REGISTRY ?= pangolin-plus
PLUS_TAG ?= local
# Source tags for retag-on-push (always built by plus-images defaults / compose)
PLUS_LOCAL_REGISTRY ?= pangolin-plus
PLUS_LOCAL_TAG ?= local
# Optional versioned tag: make plus-images VERSION=1.21.1-plus
VERSION ?=
PLUS_BUILD_VERSION = $(if $(VERSION),$(VERSION),$(PLUS_TAG))
# Staged multi-OS binaries for GitHub Releases (see plus-release-binaries)
PLUS_DIST ?= dist/plus

.PHONY: components-test components-build \
	newt-test newt-build gerbil-build olm-build badger-test \
	plus-images plus-images-push plus-image-pangolin plus-image-gerbil \
	plus-image-newt plus-image-olm plus-check-vars plus-check-docker \
	plus-check-fosrl-registry plus-guards-selftest plus-verify \
	plus-release-binaries plus-install-scripts-selftest plus-release-linux-amd64-smoke

# Shared guards for image tags (empty / unsafe chars in tag vars + retag source).
# PLUS_* values are trusted Make variables — do not pass untrusted $(shell) input.
define plus-assert-tag-vars
	@if [ -z "$(PLUS_REGISTRY)" ]; then echo "Error: PLUS_REGISTRY is empty"; exit 1; fi
	@if [ -z "$(PLUS_TAG)" ]; then echo "Error: PLUS_TAG is empty"; exit 1; fi
	@if [ -z "$(PLUS_LOCAL_REGISTRY)" ]; then echo "Error: PLUS_LOCAL_REGISTRY is empty"; exit 1; fi
	@if [ -z "$(PLUS_LOCAL_TAG)" ]; then echo "Error: PLUS_LOCAL_TAG is empty"; exit 1; fi
	@case "$(PLUS_REGISTRY)$(PLUS_TAG)$(VERSION)$(PLUS_LOCAL_REGISTRY)$(PLUS_LOCAL_TAG)" in \
		*[\'\"\\\;\|\$$\`\ \	]*) echo "Error: PLUS_REGISTRY/PLUS_TAG/VERSION/PLUS_LOCAL_* contains unsafe chars"; exit 1;; \
	esac
endef

plus-check-vars:
	$(plus-assert-tag-vars)

plus-check-docker:
	@command -v docker >/dev/null || { echo "Error: docker not found"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "Error: docker daemon not reachable"; exit 1; }

# Fosrl namespace refuse only (no docker daemon required — used by selftest + push).
plus-check-fosrl-registry:
	@if [ -z "$(PLUS_REGISTRY)" ]; then echo "Error: PLUS_REGISTRY is empty"; exit 1; fi
	@if [ "$(PLUS_REGISTRY)" = "pangolin-plus" ]; then \
		echo "Error: set PLUS_REGISTRY to a real registry (e.g. ghcr.io/88plug/pangolin-plus)"; \
		exit 1; \
	fi
	@reg_lc=$$(printf '%s' "$(PLUS_REGISTRY)" | tr '[:upper:]' '[:lower:]'); \
	case "$$reg_lc" in \
		fosrl|fosrl/*|docker.io/fosrl|docker.io/fosrl/*|index.docker.io/fosrl|index.docker.io/fosrl/*|registry-1.docker.io/fosrl|registry-1.docker.io/fosrl/*|ghcr.io/fosrl|ghcr.io/fosrl/*) \
			echo "Error: refuse push to upstream fosrl namespace ($$reg_lc)"; exit 1;; \
	esac

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
	@# Cheap binary smoke when images support --help / -h (non-fatal if entrypoint differs)
	@docker run --rm --entrypoint /usr/local/bin/newt "$(PLUS_REGISTRY)/newt:$(PLUS_TAG)" --help >/dev/null 2>&1 \
		|| docker run --rm --entrypoint /usr/local/bin/newt "$(PLUS_REGISTRY)/newt:$(PLUS_TAG)" -h >/dev/null 2>&1 \
		|| true
	@echo ""
	@echo "plus-images tagged under $(PLUS_REGISTRY)/*:$(PLUS_TAG)"
	@echo "  (badger is a Traefik plugin — compose.plus mounts components/badger as localPlugins)"
	@echo "Compose: docker compose -f compose.plus.yaml up -d"
	@echo "Lab newt:  NEWT_ID=... NEWT_SECRET=... docker compose -f compose.plus.yaml --profile lab up -d"

# Optional: push to a registry you control. Does NOT default to GHCR.
# Product default registry: ghcr.io/88plug/pangolin-plus
# Always retags from PLUS_LOCAL_REGISTRY/*:PLUS_LOCAL_TAG when src exists so a
# second push after rebuild ships the new layers (never keep a stale dest tag):
#   make plus-images
#   make plus-images-push PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus PLUS_TAG=v1.21.1-plus VERSION=1.21.1-plus
plus-images-push: plus-check-vars plus-check-fosrl-registry plus-check-docker
	@for name in pangolin gerbil newt olm; do \
		src="$(PLUS_LOCAL_REGISTRY)/$$name:$(PLUS_LOCAL_TAG)"; \
		dst="$(PLUS_REGISTRY)/$$name:$(PLUS_TAG)"; \
		if docker image inspect "$$src" >/dev/null 2>&1; then \
			echo "retag $$src -> $$dst"; \
			docker tag "$$src" "$$dst"; \
		elif docker image inspect "$$dst" >/dev/null 2>&1; then \
			echo "using existing $$dst (no $$src to retag)"; \
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

# Guard smoke: empty/unsafe vars, fosrl refuse (no docker daemon), monorepo badger,
# compose config + lab restart:"no", ansible syntax-check when available.
plus-guards-selftest: plus-check-vars
	@set -e; \
	if $(MAKE) -s plus-check-vars PLUS_LOCAL_TAG= >/dev/null 2>&1; then \
		echo "FAIL: empty PLUS_LOCAL_TAG should error"; exit 1; \
	fi; \
	if $(MAKE) -s plus-check-vars PLUS_LOCAL_REGISTRY='bad;name' >/dev/null 2>&1; then \
		echo "FAIL: unsafe PLUS_LOCAL_REGISTRY should error"; exit 1; \
	fi; \
	for reg in fosrl FOSRL/x docker.io/fosrl ghcr.io/fosrl index.docker.io/fosrl registry-1.docker.io/fosrl; do \
		if $(MAKE) -s plus-check-fosrl-registry PLUS_REGISTRY=$$reg >/dev/null 2>&1; then \
			echo "FAIL: should refuse PLUS_REGISTRY=$$reg"; exit 1; \
		fi; \
	done; \
	$(MAKE) -s plus-check-fosrl-registry PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus >/dev/null; \
	echo "fosrl refuse + allow non-fosrl: OK (no docker required)"; \
	if $(MAKE) -s check-allow-fosrl-tags >/dev/null 2>&1; then \
		echo "FAIL: check-allow-fosrl-tags should refuse without ALLOW_FOSRL_TAGS=1"; exit 1; \
	fi; \
	if $(MAKE) -s build-release tag=1.0.0 >/dev/null 2>&1; then \
		echo "FAIL: bare make build-release should refuse without ALLOW_FOSRL_TAGS=1"; exit 1; \
	fi; \
	if $(MAKE) -s build-sqlite tag=1.0.0 >/dev/null 2>&1; then \
		echo "FAIL: bare make build-sqlite should refuse without ALLOW_FOSRL_TAGS=1"; exit 1; \
	fi; \
	if $(MAKE) -s -C components/newt docker-build-release tag=1.0.0 >/dev/null 2>&1; then \
		echo "FAIL: components/newt docker-build-release should refuse without ALLOW_FOSRL_TAGS=1"; exit 1; \
	fi; \
	if $(MAKE) -s -C components/olm docker-build-release tag=1.0.0 >/dev/null 2>&1; then \
		echo "FAIL: components/olm docker-build-release should refuse without ALLOW_FOSRL_TAGS=1"; exit 1; \
	fi; \
	if $(MAKE) -s -C components/gerbil docker-build-release tag=1.0.0 >/dev/null 2>&1; then \
		echo "FAIL: components/gerbil docker-build-release should refuse without ALLOW_FOSRL_TAGS=1"; exit 1; \
	fi; \
	echo "ALLOW_FOSRL_TAGS refuse (build-release + build-sqlite + component push): OK"; \
	# Keep plus_re byte-aligned with deploy/upgrade-pangolin.yml plus_image_re \
	plus_re='^(docker\.io/|index\.docker\.io/|registry-1\.docker\.io/)?(pangolin-plus/|ghcr\.io/88plug/pangolin-plus/)'; \
	playbook_re=$$(grep -E "plus_image_re:" deploy/upgrade-pangolin.yml | head -1 | sed -n "s/.*plus_image_re: *['\"]\\(.*\\)['\"].*/\\1/p"); \
	if [ -n "$$playbook_re" ] && [ "$$playbook_re" != "$$plus_re" ]; then \
		echo "FAIL: plus_re != upgrade-pangolin.yml plus_image_re"; \
		echo "  selftest: $$plus_re"; \
		echo "  playbook: $$playbook_re"; \
		exit 1; \
	fi; \
	for img in \
		'pangolin-plus/pangolin:local' \
		'ghcr.io/88plug/pangolin-plus/pangolin:v1.21.1-plus' \
		'docker.io/pangolin-plus/gerbil:local' \
		'ghcr.io/88plug/pangolin-plus/gerbil:v1.21.1-plus'; do \
		printf '%s' "$$img" | grep -Eq "$$plus_re" \
			|| { echo "FAIL: plus-family regex should match $$img"; exit 1; }; \
	done; \
	for img in 'fosrl/pangolin:latest' 'fosrl/gerbil:latest' 'ghcr.io/fosrl/pangolin:1.21.1'; do \
		printf '%s' "$$img" | grep -Eq "$$plus_re" \
			&& { echo "FAIL: plus-family regex should NOT match $$img"; exit 1; }; \
	done; \
	echo "plus-family demote regex: OK"; \
	test -f components/badger/go.mod || { echo "FAIL: missing components/badger/go.mod"; exit 1; }; \
	test -f config/traefik/traefik_config.plus.yml || { echo "FAIL: missing traefik_config.plus.yml"; exit 1; }; \
	grep -q 'localPlugins' config/traefik/traefik_config.plus.yml || { echo "FAIL: plus traefik config missing localPlugins"; exit 1; }; \
	grep -q 'plugins:' config/traefik/traefik_config.yml || { echo "FAIL: stock traefik_config.yml missing catalog plugins"; exit 1; }; \
	command -v docker >/dev/null && docker info >/dev/null 2>&1 && { \
		docker compose -f compose.plus.yaml config >/dev/null; \
		lab_cfg=$$(docker compose -f compose.plus.yaml --profile lab config); \
		echo "$$lab_cfg" | grep -E "restart:[[:space:]]*['\"]?no['\"]?" >/dev/null \
			|| { echo "FAIL: lab profile missing restart: no"; exit 1; }; \
		echo "$$lab_cfg" | grep -q 'newt-lab' || { echo "FAIL: lab missing newt-lab"; exit 1; }; \
		echo "$$lab_cfg" | grep -q 'traefik_config.plus.yml' \
			|| { echo "FAIL: compose.plus not using traefik_config.plus.yml"; exit 1; }; \
		docker compose -f compose.example.yaml config >/dev/null; \
		echo "compose config: OK (plus default + lab restart:no + example)"; \
	} || echo "compose config: skip (no docker)"; \
	if command -v ansible-playbook >/dev/null 2>&1; then \
		for pb in deploy/pangolin.yml deploy/playbook-simple.yml deploy/playbook-debian-trixie.yml deploy/upgrade-pangolin.yml; do \
			ansible-playbook --syntax-check "$$pb" >/dev/null; \
			echo "syntax-check $$pb: OK"; \
		done; \
	else \
		echo "ansible-playbook: skip (not installed)"; \
	fi; \
	$(MAKE) -s plus-install-scripts-selftest; \
	echo "plus-guards-selftest: PASS"

# Behavioral smoke for get-plus install scripts (no network for core paths).
plus-install-scripts-selftest:
	@chmod +x scripts/plus-install-scripts-selftest.sh scripts/get-plus-*.sh
	@sh scripts/plus-install-scripts-selftest.sh

# Composite verify for plus client stack wiring (no full image build unless already present)
plus-verify: plus-guards-selftest components-build components-test
	@echo "plus-verify: PASS"

# --- plus multi-OS release binaries (GitHub Release assets) ---
# Builds component go-build-release targets and stages under dist/plus/ with
# upstream asset names (newt_linux_amd64, olm_darwin_arm64, gerbil_linux_amd64, …).
# Binary names inside archives stay newt/olm/gerbil; release assets keep platform suffix.
#
#   make plus-release-binaries VERSION=1.21.1-plus
#   ls dist/plus/
#
# Exact expected basenames (newt×10 + olm×8 + gerbil×2 = 20; + SHA256SUMS).
# Keep in sync with components/*/Makefile go-build-release targets.
PLUS_RELEASE_EXPECTED_ASSETS := \
	gerbil_linux_amd64 \
	gerbil_linux_arm64 \
	newt_darwin_amd64 \
	newt_darwin_arm64 \
	newt_freebsd_amd64 \
	newt_freebsd_arm64 \
	newt_linux_amd64 \
	newt_linux_arm32 \
	newt_linux_arm32v6 \
	newt_linux_arm64 \
	newt_linux_riscv64 \
	newt_windows_amd64.exe \
	olm_darwin_amd64 \
	olm_darwin_arm64 \
	olm_linux_amd64 \
	olm_linux_arm32 \
	olm_linux_arm32v6 \
	olm_linux_arm64 \
	olm_linux_riscv64 \
	olm_windows_amd64.exe

# Lightweight CI smoke: linux/amd64 clients only (no full multi-OS matrix).
plus-release-linux-amd64-smoke:
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION required. Usage: make plus-release-linux-amd64-smoke VERSION=1.21.1-plus"; \
		exit 1; \
	fi
	@printf '%s' "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+-plus(\.[a-zA-Z0-9.]+)?$$' \
		|| { echo "Error: VERSION must match N.N.N-plus, got: $(VERSION)"; exit 1; }
	@command -v go >/dev/null || { echo "Error: go not found"; exit 1; }
	@mkdir -p components/newt/bin components/olm/bin components/gerbil/bin "$(PLUS_DIST)"
	$(MAKE) -C components/newt go-build-release-linux-amd64 VERSION="$(VERSION)"
	$(MAKE) -C components/olm go-build-release-linux-amd64 VERSION="$(VERSION)"
	@cd components/gerbil && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/gerbil_linux_amd64 .
	@cp -f components/newt/bin/newt_linux_amd64 components/olm/bin/olm_linux_amd64 \
		components/gerbil/bin/gerbil_linux_amd64 "$(PLUS_DIST)/"
	@set -e; \
	newt_ver=$$("$(PLUS_DIST)/newt_linux_amd64" --version 2>/dev/null || true); \
	olm_ver=$$("$(PLUS_DIST)/olm_linux_amd64" --version 2>/dev/null || true); \
	echo "smoke newt --version: $$newt_ver"; \
	echo "smoke olm --version: $$olm_ver"; \
	printf '%s' "$$newt_ver" | grep -Fq "$(VERSION)" \
		|| { echo "Error: newt --version missing VERSION=$(VERSION): $$newt_ver"; exit 1; }; \
	printf '%s' "$$olm_ver" | grep -Fq "$(VERSION)" \
		|| { echo "Error: olm --version missing VERSION=$(VERSION): $$olm_ver"; exit 1; }; \
	test -x "$(PLUS_DIST)/gerbil_linux_amd64"; \
	echo "plus-release-linux-amd64-smoke: PASS"

plus-release-binaries:
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION is required. Usage: make plus-release-binaries VERSION=1.21.1-plus"; \
		exit 1; \
	fi
	@case "$(VERSION)" in \
		*[\'\"\\\;\|\$$\`\ \	]*) echo "Error: VERSION contains unsafe chars"; exit 1;; \
	esac
	@# Allowlist aligns with plus-release.yml (no leading v in VERSION for ldflags)
	@printf '%s' "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+-plus(\.[a-zA-Z0-9.]+)?$$' \
		|| { echo "Error: VERSION must match N.N.N-plus (optional .suffix), got: $(VERSION)"; exit 1; }
	@command -v go >/dev/null || { echo "Error: go not found"; exit 1; }
	@rm -rf "$(PLUS_DIST)"
	@mkdir -p "$(PLUS_DIST)"
	@# Clean CI checkouts often lack gitignored bin/ dirs
	@mkdir -p components/newt/bin components/olm/bin components/gerbil/bin
	@echo "Building newt release binaries (VERSION=$(VERSION))..."
	$(MAKE) -C components/newt go-build-release VERSION="$(VERSION)"
	@echo "Building olm release binaries (VERSION=$(VERSION))..."
	$(MAKE) -C components/olm go-build-release VERSION="$(VERSION)"
	@echo "Building gerbil release binaries (linux amd64/arm64)..."
	$(MAKE) -C components/gerbil go-build-release
	@# Stage with stable asset names (underscores — matches get-plus-*.sh / upstream get-*.sh)
	@set -e; \
	for f in components/newt/bin/newt_*; do \
		[ -f "$$f" ] || continue; \
		cp -f "$$f" "$(PLUS_DIST)/$$(basename "$$f")"; \
	done; \
	for f in components/olm/bin/olm_*; do \
		[ -f "$$f" ] || continue; \
		cp -f "$$f" "$(PLUS_DIST)/$$(basename "$$f")"; \
	done; \
	for f in components/gerbil/bin/gerbil_*; do \
		[ -f "$$f" ] || continue; \
		cp -f "$$f" "$(PLUS_DIST)/$$(basename "$$f")"; \
	done; \
	missing=0; \
	for name in $(PLUS_RELEASE_EXPECTED_ASSETS); do \
		if [ ! -f "$(PLUS_DIST)/$$name" ]; then \
			echo "Error: missing expected asset $$name"; \
			missing=1; \
		fi; \
	done; \
	if [ "$$missing" -ne 0 ]; then \
		echo "Staged files:"; ls -la "$(PLUS_DIST)" || true; \
		exit 1; \
	fi; \
	count=$$(find "$(PLUS_DIST)" -type f ! -name SHA256SUMS | wc -l); \
	expected=$$(printf '%s\n' $(PLUS_RELEASE_EXPECTED_ASSETS) | wc -w); \
	if [ "$$count" -ne "$$expected" ]; then \
		echo "Error: expected exactly $$expected assets, found $$count (extra basenames?)"; \
		ls -la "$(PLUS_DIST)" || true; \
		exit 1; \
	fi; \
	for f in "$(PLUS_DIST)"/*; do \
		base=$$(basename "$$f"); \
		[ "$$base" = "SHA256SUMS" ] && continue; \
		ok=0; \
		for name in $(PLUS_RELEASE_EXPECTED_ASSETS); do \
			[ "$$base" = "$$name" ] && ok=1 && break; \
		done; \
		if [ "$$ok" -ne 1 ]; then \
			echo "Error: unexpected asset $$base"; exit 1; \
		fi; \
	done; \
	test -x "$(PLUS_DIST)/newt_linux_amd64" || { echo "Error: missing newt_linux_amd64"; exit 1; }; \
	test -x "$(PLUS_DIST)/olm_linux_amd64" || { echo "Error: missing olm_linux_amd64"; exit 1; }; \
	test -x "$(PLUS_DIST)/gerbil_linux_amd64" || { echo "Error: missing gerbil_linux_amd64"; exit 1; }; \
	newt_ver=$$("$(PLUS_DIST)/newt_linux_amd64" --version 2>/dev/null || true); \
	olm_ver=$$("$(PLUS_DIST)/olm_linux_amd64" --version 2>/dev/null || true); \
	echo "smoke newt --version: $$newt_ver"; \
	echo "smoke olm --version: $$olm_ver"; \
	printf '%s' "$$newt_ver" | grep -Fq "$(VERSION)" \
		|| { echo "Error: newt --version missing VERSION=$(VERSION): $$newt_ver"; exit 1; }; \
	printf '%s' "$$olm_ver" | grep -Fq "$(VERSION)" \
		|| { echo "Error: olm --version missing VERSION=$(VERSION): $$olm_ver"; exit 1; }; \
	( cd "$(PLUS_DIST)" && sha256sum $(PLUS_RELEASE_EXPECTED_ASSETS) > SHA256SUMS ); \
	( cd "$(PLUS_DIST)" && sha256sum -c SHA256SUMS >/dev/null ); \
	echo "SHA256SUMS: verified (sha256sum -c)"; \
	echo ""; \
	echo "plus-release-binaries: $$count assets + SHA256SUMS → $(PLUS_DIST)/"; \
	ls -la "$(PLUS_DIST)"
