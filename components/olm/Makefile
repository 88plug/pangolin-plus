.PHONY: all local docker-build-release

all: local

VERSION ?= dev
LDFLAGS = -X main.olmVersion=$(VERSION)
# Local monorepo image namespace (product path). Published: ghcr.io/88plug/pangolin-plus/olm
PLUS_IMAGE ?= pangolin-plus/olm

local:
	CGO_ENABLED=0 go build -o ./bin/olm

# Local load only — never pushes.
docker-build:
	docker build -t $(PLUS_IMAGE):local -t $(PLUS_IMAGE):latest .

# Upstream-shaped multi-arch push to fosrl/olm (gated). Prefer monorepo plus-images-push.
docker-build-release:
	@if [ "$(ALLOW_FOSRL_TAGS)" != "1" ]; then \
		echo "Error: docker-build-release tags/pushes fosrl/olm:* (legacy only)."; \
		echo "  Product: make -C ../.. plus-images  |  plus-images-push PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus"; \
		echo "  Force:   ALLOW_FOSRL_TAGS=1 make docker-build-release tag=<tag>"; \
		exit 1; \
	fi
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make docker-build-release tag=<tag>"; \
		exit 1; \
	fi
	docker buildx build . \
		--platform linux/arm/v7,linux/arm64,linux/amd64 \
		-t fosrl/olm:latest \
		-t fosrl/olm:$(tag) \
		-f Dockerfile \
		--push

# Multi-arch build (no push; buildx cache only unless single-platform --load).
docker-build-dev:
	docker buildx build . \
		--platform linux/arm/v7,linux/arm64,linux/amd64 \
		-t $(PLUS_IMAGE):local \
		-t $(PLUS_IMAGE):latest \
		-f Dockerfile

.PHONY: go-build-release \
        go-build-release-linux-arm64 go-build-release-linux-arm32-v7 \
        go-build-release-linux-arm32-v6 go-build-release-linux-amd64 \
        go-build-release-linux-riscv64 go-build-release-darwin-arm64 \
        go-build-release-darwin-amd64 go-build-release-windows-amd64

go-build-release: \
    go-build-release-linux-arm64 \
    go-build-release-linux-arm32-v7 \
    go-build-release-linux-arm32-v6 \
    go-build-release-linux-amd64 \
    go-build-release-linux-riscv64 \
    go-build-release-darwin-arm64 \
    go-build-release-darwin-amd64 \
    go-build-release-windows-amd64 \

go-build-release-linux-arm64:
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o bin/olm_linux_arm64

go-build-release-linux-arm32-v7:
	CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 go build -ldflags "$(LDFLAGS)" -o bin/olm_linux_arm32

go-build-release-linux-arm32-v6:
	CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=6 go build -ldflags "$(LDFLAGS)" -o bin/olm_linux_arm32v6

go-build-release-linux-amd64:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o bin/olm_linux_amd64

go-build-release-linux-riscv64:
	CGO_ENABLED=0 GOOS=linux GOARCH=riscv64 go build -ldflags "$(LDFLAGS)" -o bin/olm_linux_riscv64

go-build-release-darwin-arm64:
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o bin/olm_darwin_arm64

go-build-release-darwin-amd64:
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o bin/olm_darwin_amd64

go-build-release-windows-amd64:
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o bin/olm_windows_amd64.exe