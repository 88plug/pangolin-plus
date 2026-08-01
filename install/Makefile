all: go-build-release

# pangolin-plus product defaults — GHCR image tags on 88plug/pangolin-plus.
# Override: make go-build-release PANGOLIN_VERSION=v1.21.2-plus GERBIL_VERSION=v1.21.2-plus
# Stock fosrl (no plus deltas): set versions from fosrl tags and edit docker-compose image lines.

PLUS_RELEASES_API ?= https://api.github.com/repos/88plug/pangolin-plus/releases/latest
PANGOLIN_VERSION ?= $(shell curl -fsSL $(PLUS_RELEASES_API) 2>/dev/null | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
ifeq ($(strip $(PANGOLIN_VERSION)),)
PANGOLIN_VERSION := v1.21.2-plus
endif
# Same monorepo release tags all four images
GERBIL_VERSION ?= $(PANGOLIN_VERSION)
# Catalog plugin version when installer still uses Traefik experimental.plugins (not monorepo localPlugins)
BADGER_VERSION ?= v1.5.0

LDFLAGS = -X main.pangolinVersion=$(PANGOLIN_VERSION) \
          -X main.gerbilVersion=$(GERBIL_VERSION) \
          -X main.badgerVersion=$(BADGER_VERSION)

go-build-release:
	@echo "Building installer (plus images: pangolin=$(PANGOLIN_VERSION) gerbil=$(GERBIL_VERSION) badger-catalog=$(BADGER_VERSION))"
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o bin/installer_linux_amd64 .
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o bin/installer_linux_arm64 .

clean:
	rm -f bin/installer_linux_amd64
	rm -f bin/installer_linux_arm64

.PHONY: all go-build-release clean
