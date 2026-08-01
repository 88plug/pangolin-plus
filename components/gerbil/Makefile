GO_VERSION := $(shell cat .go-version 2>/dev/null)
# Local monorepo image namespace (product path). Published: ghcr.io/88plug/pangolin-plus/gerbil
PLUS_IMAGE ?= pangolin-plus/gerbil

# Default: local Go binary only (never docker push).
all: local

# Upstream-shaped multi-arch push to fosrl/gerbil (gated). Prefer monorepo plus-images-push.
docker-build-release:
	@if [ "$(ALLOW_FOSRL_TAGS)" != "1" ]; then \
		echo "Error: docker-build-release tags/pushes fosrl/gerbil:* (legacy only)."; \
		echo "  Product: make -C ../.. plus-images  |  plus-images-push PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus"; \
		echo "  Force:   ALLOW_FOSRL_TAGS=1 make docker-build-release tag=<tag>"; \
		exit 1; \
	fi
	@if [ -z "$(tag)" ]; then \
		echo "Error: tag is required. Usage: make docker-build-release tag=<tag>"; \
		exit 1; \
	fi
	docker buildx build --platform linux/arm64,linux/amd64 -t fosrl/gerbil:latest -f Dockerfile --push .
	docker buildx build --platform linux/arm64,linux/amd64 -t fosrl/gerbil:$(tag) -f Dockerfile --build-arg GO_VERSION=$(GO_VERSION) --push .

# Local load only — never pushes.
build:
	docker build -t $(PLUS_IMAGE):local -t $(PLUS_IMAGE):latest --build-arg GO_VERSION=$(GO_VERSION) .

# Gated: only push fosrl tags when explicitly allowed (legacy).
push:
	@if [ "$(ALLOW_FOSRL_TAGS)" != "1" ]; then \
		echo "Error: push targets fosrl/gerbil:latest (legacy only)."; \
		echo "  Product: make -C ../.. plus-images-push PLUS_REGISTRY=ghcr.io/88plug/pangolin-plus"; \
		echo "  Force:   ALLOW_FOSRL_TAGS=1 make push"; \
		exit 1; \
	fi
	docker push fosrl/gerbil:latest

test:
	docker run -it -p 3002:3002 -v ./config_example.json:/config/config.json --cap-add=NET_ADMIN --cap-add=SYS_MODULE $(PLUS_IMAGE):local --config /config/config.json

local:
	mkdir -p bin
	CGO_ENABLED=0 go build -o bin/gerbil


go-build-release:
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o bin/gerbil_linux_arm64
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/gerbil_linux_amd64

clean:
	rm -f gerbil bin/gerbil
