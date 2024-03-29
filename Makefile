GOMOD ?= on
GO ?= GO111MODULE=$(GOMOD) go

#Don't enable mod=vendor when GOMOD is off or else go build/install will fail
GOMODFLAG ?=-mod=vendor
ifeq ($(GOMOD), off)
GOMODFLAG=
endif

#retrieve go version details for version check
GO_VERSION     := $(shell $(GO) version | sed -e 's/^[^0-9.]*\([0-9.]*\).*/\1/')
GO_VERSION_MAJ := $(shell echo $(GO_VERSION) | cut -f1 -d'.')
GO_VERSION_MIN := $(shell echo $(GO_VERSION) | cut -f2 -d'.')

GOFMT ?= gofmt
TERRAFORM ?= $(shell which terraform 2>/dev/null || which true 2>/dev/null)
GO_MD2MAN ?= go-md2man
LN = ln
RM = rm

GOBINPATH     := $(shell $(GO) env GOPATH)/bin
COMMIT        := $(shell git rev-parse HEAD)
BUILD_DATE    := $(shell date +%Y%m%d)
# TAG can be provided as an envvar (provided in the .spec file)
TAG           ?= $(shell git show-ref --tags | grep $(COMMIT) | awk '{print $2}' | cut -d/ -f3)
# ANNOTATED_TAG can be provided as an envvar (provided in the .spec file)
ANNOTATED_TAG ?= $(shell git describe --tag)
# VERSION is inferred from TAG
# It accepts tags of type `vX.Y.Z`, `vX.Y.Z-(alpha|beta|rc|...)` and produces X.Y.Z
VERSION       := $(shell echo $(TAG) | sed -E 's/v(([0-9]\.?)+).*/\1/')
TAGS          := development
PROJECT_PATH  := github.com/SUSE/skuba
SKUBA_LDFLAGS  = -ldflags "-X=$(PROJECT_PATH)/pkg/skuba.Version=$(VERSION) \
                           -X=$(PROJECT_PATH)/pkg/skuba.BuildDate=$(BUILD_DATE) \
                           -X=$(PROJECT_PATH)/pkg/skuba.Tag=$(TAG) \
                           -X=$(PROJECT_PATH)/pkg/skuba.AnnotatedTag=$(ANNOTATED_TAG)"

SKUBA_DIRS     = cmd pkg internal test

# go source files, ignore vendor directory
SKUBA_SRCS     = $(shell find $(SKUBA_DIRS) -type f -name '*.go')

.PHONY: all
all: install

.PHONY: build
build: go-version-check
	$(GO) build $(GOMODFLAG) $(SKUBA_LDFLAGS) -tags $(TAGS) ./cmd/...

MANPAGES_MD := $(wildcard docs/man/*.md)
MANPAGES    := $(MANPAGES_MD:%.md=%)

docs/man/%.1: docs/man/%.1.md
	$(GO_MD2MAN) -in $< -out $@

.PHONY: docs
docs: $(MANPAGES)

.PHONY: install
install: go-version-check
	$(GO) install $(GOMODFLAG) $(SKUBA_LDFLAGS) -tags $(TAGS) ./cmd/...
	$(RM) -f $(GOBINPATH)/kubectl-caasp
	$(LN) -s $(GOBINPATH)/skuba $(GOBINPATH)/kubectl-caasp

.PHONY: clean
clean:
	$(GO) clean -i
	$(RM) -f ./skuba

.PHONY: distclean
distclean: clean
	$(GO) clean -i -cache -testcache -modcache

.PHONY: staging
staging:
	make TAGS=staging install

.PHONY: release
release:
	make TAGS=release install

.PHONY: go-version-check
go-version-check:
	@[ $(GO_VERSION_MAJ) -ge 2 ] || \
		[ $(GO_VERSION_MAJ) -eq 1 -a $(GO_VERSION_MIN) -ge 12 ] || (echo "FATAL: Go version should be >= 1.12.x" ; exit 1 ; )

.PHONY: lint
lint:
	# explicitly enable GO111MODULE otherwise go mod will fail
	GO111MODULE=on go mod tidy && GO111MODULE=on go mod vendor && GO111MODULE=on go mod verify
	$(GO) vet ./...
	test -z `$(GOFMT) -l $(SKUBA_SRCS)` || { $(GOFMT) -d $(SKUBA_SRCS) && false; }
	$(TERRAFORM) fmt -check=true -write=false -diff=true ci/infra
	find ci -type f -name "*.sh" | xargs bashate

.PHONY: suse-package
suse-package:
	ci/packaging/suse/rpmfiles_maker.sh "$(VERSION)" "$(TAG)" "$(ANNOTATED_TAG)"

.PHONY: suse-changelog
suse-changelog:
	ci/packaging/suse/changelog_maker.sh "$(CHANGES)"

# tests
.PHONY: test
test: test-unit test-e2e

.PHONY: test-unit
test-unit:
	$(GO) test $(GOMODFLAG) -coverprofile=coverage.out $(PROJECT_PATH)/{cmd,pkg,internal}/...

.PHONY: test-unit-coverage
test-unit-coverage: test-unit
	$(GO) tool cover -html=coverage.out

.PHONY: test-e2e
test-e2e:
	./ci/tasks/e2e-tests.py

# this target are called from skuba dir mainly not from CI dir
# build ginkgo executables from vendor (used in CI)
.PHONY: build-ginkgo
build-ginkgo:
	$(GO) build -o ginkgo ./vendor/github.com/onsi/ginkgo/ginkgo

.PHONY: setup-ssh
setup-ssh:
	./ci/tasks/setup-ssh.py
