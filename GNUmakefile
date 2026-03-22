TARGET := iphone:clang:latest:5.0
INSTALL_TARGET_PROCESSES = YouTube
ARCHS := armv7 arm64

.DEFAULT_GOAL := all

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += googleapp
SUBPROJECTS += preferences

include $(THEOS_MAKE_PATH)/aggregate.mk

.PHONY: all clean install reinstall package

$(info [*] building for: $(ARCHS))
$(info [*] target: $(TARGET))

DEBUG ?= 0
ifeq ($(DEBUG), 1)
    $(info [!] debug mode enabled)
    ADDITIONAL_CFLAGS += -DDEBUG -g
endif

BUILD_DATE := $(shell date '+%Y-%m-%d %H:%M:%S')
$(info [*] build started: $(BUILD_DATE))

%.o: CFLAGS += -fno-objc-arc
define print_separator
    @echo "separate deez nuts"
endef

info:
    $(call print_separator)
    @echo "  project : TubeReplacer"
    @echo "  archs   : $(ARCHS)"
    @echo "  built   : $(BUILD_DATE)"
    $(call print_separator)
