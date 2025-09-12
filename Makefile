CJSON_OBJ = cJSON.o
UTILS_OBJ = cJSON_Utils.o
CJSON_LIBNAME = libcjson
UTILS_LIBNAME = libcjson_utils
CJSON_TEST = cJSON_test

CJSON_TEST_SRC = cJSON.c test.c

LDLIBS = -lm

LIBVERSION = 1.7.18
CJSON_SOVERSION = 1
UTILS_SOVERSION = 1

CJSON_SO_LDFLAG=-Wl,-soname=$(CJSON_LIBNAME).so.$(CJSON_SOVERSION)
UTILS_SO_LDFLAG=-Wl,-soname=$(UTILS_LIBNAME).so.$(UTILS_SOVERSION)
# 1. 基础配置：默认架构（可手动指定 ARCH=arm64 切换）
#    使用方法：make ARCH=arm32  # 编译arm32
#             make ARCH=arm64  # 编译arm64
ARCH ?= arm32  # 默认编译arm32，可覆盖

PREFIX ?= $(PWD)/ken_result
# PREFIX ?= /usr/local
INCLUDE_PATH ?= include/cjson
LIBRARY_PATH ?= lib

# INSTALL_INCLUDE_PATH = $(DESTDIR)$(PREFIX)/$(INCLUDE_PATH)
# INSTALL_LIBRARY_PATH = $(DESTDIR)$(PREFIX)/$(LIBRARY_PATH)

INSTALL_INCLUDE_PATH = $(DESTDIR)$(PREFIX)/$(ARCH)/$(INCLUDE_PATH)
INSTALL_LIBRARY_PATH = $(DESTDIR)$(PREFIX)/$(ARCH)/$(LIBRARY_PATH)

INSTALL ?= cp -a

#arm64
# CROSS_COMPILE:=/home/quan/share/zc0203_skdl0401p/tools/gcc-10.2.1-20210303-sigmastar-glibc-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
#arm32
# CROSS_COMPILE:=/home/quan/share/sktc0405/tools/gcc-11.1.0-20210608-sigmastar-glibc-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
# CC = $(CROSS_COMPILE)gcc
# CC = gcc -std=c89

ifeq ($(ARCH),arm32)
    # arm32 工具链路径（你的原arm32配置）
    CROSS_COMPILE := /home/quan/share/sktc0405/tools/gcc-11.1.0-20210608-sigmastar-glibc-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
else ifeq ($(ARCH),arm64)
    # arm64 工具链路径（你的原arm64配置）
    CROSS_COMPILE := /home/quan/share/skdl0402p/tools/gcc-10.2.1-20210303-sigmastar-glibc-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
else
    # 错误处理：若指定未知架构，编译报错
    $(error "Unsupported ARCH: $(ARCH)! Use 'ARCH=arm32' or 'ARCH=arm64'")
endif
CC = $(CROSS_COMPILE)gcc



# validate gcc version for use fstack-protector-strong
MIN_GCC_VERSION = "4.9"
GCC_VERSION := "`$(CC) -dumpversion`"
IS_GCC_ABOVE_MIN_VERSION := $(shell expr "$(GCC_VERSION)" ">=" "$(MIN_GCC_VERSION)")
ifeq "$(IS_GCC_ABOVE_MIN_VERSION)" "1"
    CFLAGS += -fstack-protector-strong
else
    CFLAGS += -fstack-protector
endif

PIC_FLAGS = -fPIC
R_CFLAGS = $(PIC_FLAGS) -pedantic -Wall -Werror -Wstrict-prototypes -Wwrite-strings -Wshadow -Winit-self -Wcast-align -Wformat=2 -Wmissing-prototypes -Wstrict-overflow=2 -Wcast-qual -Wc++-compat -Wundef -Wswitch-default -Wconversion $(CFLAGS)

uname := $(shell sh -c 'uname -s 2>/dev/null || echo false')

#library file extensions
SHARED = so
STATIC = a

## create dynamic (shared) library on Darwin (base OS for MacOSX and IOS)
ifeq (Darwin, $(uname))
	SHARED = dylib
	CJSON_SO_LDFLAG = ""
	UTILS_SO_LDFLAG = ""
endif

#cJSON library names
CJSON_SHARED = $(CJSON_LIBNAME).$(SHARED)
CJSON_SHARED_VERSION = $(CJSON_LIBNAME).$(SHARED).$(LIBVERSION)
CJSON_SHARED_SO = $(CJSON_LIBNAME).$(SHARED).$(CJSON_SOVERSION)
CJSON_STATIC = $(CJSON_LIBNAME).$(STATIC)

#cJSON_Utils library names
UTILS_SHARED = $(UTILS_LIBNAME).$(SHARED)
UTILS_SHARED_VERSION = $(UTILS_LIBNAME).$(SHARED).$(LIBVERSION)
UTILS_SHARED_SO = $(UTILS_LIBNAME).$(SHARED).$(UTILS_SOVERSION)
UTILS_STATIC = $(UTILS_LIBNAME).$(STATIC)

SHARED_CMD = $(CC) -shared -o

.PHONY: all shared static tests clean install

all: shared static tests

shared: $(CJSON_SHARED) $(UTILS_SHARED)

static: $(CJSON_STATIC) $(UTILS_STATIC)

tests: $(CJSON_TEST)

test: tests
	./$(CJSON_TEST)

.c.o:
	$(CC) -c $(R_CFLAGS) $<

#tests
#cJSON
$(CJSON_TEST): $(CJSON_TEST_SRC) cJSON.h
	$(CC) $(R_CFLAGS) $(CJSON_TEST_SRC)  -o $@ $(LDLIBS) -I.

#static libraries
#cJSON
$(CJSON_STATIC): $(CJSON_OBJ)
	$(AR) rcs $@ $<
#cJSON_Utils
$(UTILS_STATIC): $(UTILS_OBJ)
	$(AR) rcs $@ $<

#shared libraries .so.1.0.0
#cJSON
$(CJSON_SHARED_VERSION): $(CJSON_OBJ)
	$(CC) -shared -o $@ $< $(CJSON_SO_LDFLAG) $(LDFLAGS)
#cJSON_Utils
$(UTILS_SHARED_VERSION): $(UTILS_OBJ)
	$(CC) -shared -o $@ $< $(CJSON_OBJ) $(UTILS_SO_LDFLAG) $(LDFLAGS)

#objects
#cJSON
$(CJSON_OBJ): cJSON.c cJSON.h
#cJSON_Utils
$(UTILS_OBJ): cJSON_Utils.c cJSON_Utils.h cJSON.h


#links .so -> .so.1 -> .so.1.0.0
#cJSON
$(CJSON_SHARED_SO): $(CJSON_SHARED_VERSION)
	ln -s $(CJSON_SHARED_VERSION) $(CJSON_SHARED_SO)
$(CJSON_SHARED): $(CJSON_SHARED_SO)
	ln -s $(CJSON_SHARED_SO) $(CJSON_SHARED)
#cJSON_Utils
$(UTILS_SHARED_SO): $(UTILS_SHARED_VERSION)
	ln -s $(UTILS_SHARED_VERSION) $(UTILS_SHARED_SO)
$(UTILS_SHARED): $(UTILS_SHARED_SO)
	ln -s $(UTILS_SHARED_SO) $(UTILS_SHARED)

#install
#cJSON
install-cjson:
	mkdir -p $(INSTALL_LIBRARY_PATH) $(INSTALL_INCLUDE_PATH)
	$(INSTALL) cJSON.h $(INSTALL_INCLUDE_PATH)
	$(INSTALL) $(CJSON_SHARED) $(CJSON_SHARED_SO) $(CJSON_SHARED_VERSION) $(INSTALL_LIBRARY_PATH)
#cJSON_Utils
install-utils: install-cjson
	$(INSTALL) cJSON_Utils.h $(INSTALL_INCLUDE_PATH)
	$(INSTALL) $(UTILS_SHARED) $(UTILS_SHARED_SO) $(UTILS_SHARED_VERSION) $(INSTALL_LIBRARY_PATH)

install: install-cjson install-utils

#uninstall
#cJSON
uninstall-cjson: uninstall-utils
	$(RM) $(INSTALL_LIBRARY_PATH)/$(CJSON_SHARED)
	$(RM) $(INSTALL_LIBRARY_PATH)/$(CJSON_SHARED_VERSION)
	$(RM) $(INSTALL_LIBRARY_PATH)/$(CJSON_SHARED_SO)
	$(RM) $(INSTALL_INCLUDE_PATH)/cJSON.h
	
#cJSON_Utils
uninstall-utils:
	$(RM) $(INSTALL_LIBRARY_PATH)/$(UTILS_SHARED)
	$(RM) $(INSTALL_LIBRARY_PATH)/$(UTILS_SHARED_VERSION)
	$(RM) $(INSTALL_LIBRARY_PATH)/$(UTILS_SHARED_SO)
	$(RM) $(INSTALL_INCLUDE_PATH)/cJSON_Utils.h

remove-dir:
	$(if $(wildcard $(INSTALL_LIBRARY_PATH)/*.*),,rmdir $(INSTALL_LIBRARY_PATH))
	$(if $(wildcard $(INSTALL_INCLUDE_PATH)/*.*),,rmdir $(INSTALL_INCLUDE_PATH))

uninstall: uninstall-utils uninstall-cjson remove-dir

clean:
	$(RM) $(CJSON_OBJ) $(UTILS_OBJ) #delete object files
	$(RM) $(CJSON_SHARED) $(CJSON_SHARED_VERSION) $(CJSON_SHARED_SO) $(CJSON_STATIC) #delete cJSON
	$(RM) $(UTILS_SHARED) $(UTILS_SHARED_VERSION) $(UTILS_SHARED_SO) $(UTILS_STATIC) #delete cJSON_Utils
	$(RM) $(CJSON_TEST)  #delete test
