ARCHS ?= armv6 arm64
target ?= iphone:clang:9.3:2.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = plutil
plutil_FILES = $(wildcard json-framework/Classes/*.m) plutil.m iphone-3.0-cookbook-/C16-Push/02-PushUtil/JSONHelper.m
plutil_CODESIGN_FLAGS = -Sent.xml

include $(THEOS_MAKE_PATH)/tool.mk
