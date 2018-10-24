NAME=hcloud-csi-driver
OS ?= linux
ifeq ($(strip $(shell git status --porcelain 2>/dev/null)),)
  GIT_TREE_STATE=clean
else
  GIT_TREE_STATE=dirty
endif
COMMIT ?= $(shell git rev-parse HEAD)
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
LDFLAGS ?= -X github.com/apricote/hcloud-csi-driver/driver.version=${VERSION} -X github.com/apricote/hcloud-csi-driver/driver.commit=${COMMIT} -X github.com/apricote/hcloud-csi-driver/driver.gitTreeState=${GIT_TREE_STATE}
PKG ?= github.com/apricote/hcloud-csi-driver/cmd/hcloud-csi-driver

## Bump the version in the version file. Set BUMP to [ patch | major | minor ]
BUMP := patch
VERSION ?= $(shell cat VERSION)

all: test

publish: compile build push clean

.PHONY: bump-version
bump-version: 
	@go get -u github.com/jessfraz/junk/sembump # update sembump tool
	$(eval NEW_VERSION = $(shell sembump --kind $(BUMP) $(VERSION)))
	@echo "Bumping VERSION from $(VERSION) to $(NEW_VERSION)"
	@echo $(NEW_VERSION) > VERSION
	@cp deploy/kubernetes/releases/hcloud-csi-driver-${VERSION}.yaml deploy/kubernetes/releases/hcloud-csi-driver-${NEW_VERSION}.yaml
	@sed -i'' -e 's/${VERSION}/${NEW_VERSION}/g' deploy/kubernetes/releases/hcloud-csi-driver-${NEW_VERSION}.yaml
	@sed -i'' -e 's/${VERSION}/${NEW_VERSION}/g' README.md
	$(eval NEW_DATE = $(shell date +%Y-%m-%d))
	@sed -i'' -e 's/## unreleased/## ${NEW_VERSION} - ${NEW_DATE}/g' CHANGELOG.md 
	@ echo '## unreleased\n' | cat - CHANGELOG.md > temp && mv temp CHANGELOG.md
	@rm README.md-e CHANGELOG.md-e deploy/kubernetes/releases/hcloud-csi-driver-${NEW_VERSION}.yaml-e

.PHONY: compile
compile:
	@echo "==> Building the project"
	@env CGO_ENABLED=0 GOOS=${OS} GOARCH=amd64 go build -o cmd/hcloud-csi-driver/${NAME} -ldflags "$(LDFLAGS)" ${PKG} 


.PHONY: test
test:
	@echo "==> Testing all packages"
	@go test -v ./...

.PHONY: test-integration
test-integration:

	@echo "==> Started integration tests"
	@env GOCACHE=off go test -v -tags integration ./test/...


.PHONY: build
build:
	@echo "==> Building the docker image"
	@docker build -t apricote/hcloud-csi-driver:$(VERSION) cmd/hcloud-csi-driver -f cmd/hcloud-csi-driver/Dockerfile

.PHONY: push
push:
ifeq ($(shell [[ $(BRANCH) != "master" && $(VERSION) != "dev" ]] && echo true ),true)
	@echo "ERROR: Publishing image with a SEMVER version '$(VERSION)' is only allowed from master"
else
	@echo "==> Publishing apricote/hcloud-csi-driver:$(VERSION)"
	@docker push apricote/hcloud-csi-driver:$(VERSION)
	@echo "==> Your image is now available at apricote/hcloud-csi-driver:$(VERSION)"
endif

.PHONY: clean
clean:
	@echo "==> Cleaning releases"
	@GOOS=${OS} go clean -i -x ./...
