prefix ?= /usr/local
destdir ?= ${prefix}
config ?= release
arch ?=
static ?= false
linker ?=

BUILD_DIR ?= build/$(config)
SRC_DIR ?= corral
binary := $(BUILD_DIR)/corral
tests_binary := $(BUILD_DIR)/test

ifdef config
  ifeq (,$(filter $(config),debug release))
    $(error Unknown configuration "$(config)")
  endif
endif

ifeq ($(config),release)
	PONYC = ponyc
else
	PONYC = ponyc --debug
endif

ifneq ($(arch),)
  arch_arg := --cpu $(arch)
endif

ifdef static
  ifeq (,$(filter $(static),true false))
  	$(error "static must be true or false)
  endif
endif

ifeq ($(static),true)
  LINKER += --static 
endif

ifneq ($(linker),)
  LINKER += --link-ldcmd=$(linker)
endif

# Default to version from `VERSION` file but allowing overridding on the
# make command line like:
# make version="nightly-19710702"
# overridden version *should not* contain spaces or characters that aren't
# legal in filesystem path names
ifndef version
  version := $(shell cat VERSION)
  ifneq ($(wildcard .git),)
    sha := $(shell git rev-parse --short HEAD)
    tag := $(version)-$(sha)
  else
    tag := $(version)
  endif
else
  foo := $(shell touch VERSION)
  tag := $(version)
endif

SOURCE_FILES := $(shell find $(SRC_DIR) -path $(SRC_DIR)/test -prune -o -name \*.pony)
TEST_FILES := $(shell find $(SRC_DIR)/test -name \*.pony -o -name helper.sh)
VERSION := "$(tag) [$(config)]"
GEN_FILES_IN := $(shell find $(SRC_DIR) -name \*.pony.in)
GEN_FILES = $(patsubst %.pony.in, %.pony, $(GEN_FILES_IN))

%.pony: %.pony.in VERSION
	sed s/%%VERSION%%/$(version)/ $< > $@

$(binary): $(GEN_FILES) $(SOURCE_FILES) | $(BUILD_DIR)
	${PONYC} $(arch_arg) $(LINKER) $(SRC_DIR) -o ${BUILD_DIR}

install: $(binary)
	@echo "install"
	mkdir -p $(DESTDIR)$(prefix)/bin
	cp $^ $(DESTDIR)$(prefix)/bin

$(tests_binary): $(GEN_FILES) $(SOURCE_FILES) $(TEST_FILES) | $(BUILD_DIR)
	${PONYC} $(arch_arg) $(LINKER) --debug -o ${BUILD_DIR} $(SRC_DIR)/test

test: $(tests_binary)
	$^ --sequential

clean:
	rm -rf $(BUILD_DIR)

all: test $(binary)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: all clean install test

