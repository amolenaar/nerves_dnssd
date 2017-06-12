# Variables to override
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_LIBDIR path to libei.a
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries

# mDNSResponder version
VERSION = 765.50.9

ifneq ($(NERVES_SYSTEM),)
TARGET_OS = linux
TARGET_OPTS = HAVE_IPV6=0
else
TARGET_OS ?= x
TARGET_OPTS =
endif

CC ?= $(CROSSCOMPILER)gcc

ifeq ($(TARGET_OS),x)
LD = $(CC) -bundle -flat_namespace -undefined suppress
else
# Assume Linux/Nerves
LD = $(CC) -shared
endif

CFLAGS += -fPIC
LDFLAGS += 
BUILD_DIR ?= _build/make
BUILD_DRV_DIR = $(BUILD_DIR)/dnssd_drv

# Set Erlang-specific compile and linker flags
ERL_EI_INCLUDE_DIR ?= $(ROOTDIR)/usr/include
ERL_EI_LIBDIR ?= $(ROOTDIR)/usr/lib
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei

###
# from  mDNSResponder-$(VERSION)/mDNSPosix/Makefile:
CLIENTLIBOBJS = $(BUILD_DRV_DIR)/dnssd_clientlib.c.so.o $(BUILD_DRV_DIR)/dnssd_clientstub.c.so.o $(BUILD_DRV_DIR)/dnssd_ipc.c.so.o

.PHONY: all clean daemon lib

all: daemon lib driver

daemon: priv/sbin/mdnsd
	@echo $^ installed

lib: $(BUILD_DRV_DIR)/libdns_sd.so.1
	@echo $^ compiled

driver: lib priv/dnssd_drv.so
	@echo $^ installed

deps/mDNSResponder-$(VERSION).tar.gz:
	curl https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-$(VERSION).tar.gz -o deps/mDNSResponder-$(VERSION).tar.gz --create-dirs

$(BUILD_DIR)/mDNSResponder-$(VERSION): deps/mDNSResponder-$(VERSION).tar.gz
	mkdir -p $(BUILD_DIR)
	tar xzf deps/mDNSResponder-$(VERSION).tar.gz -C $(BUILD_DIR)

##
# The daemon
#
# TODO: can be done in one shot
$(BUILD_DIR)/mdnsd/mdnsd: $(BUILD_DIR)/mDNSResponder-$(VERSION)
	make -C $(BUILD_DIR)/mDNSResponder-$(VERSION)/mDNSPosix Daemon os=$(TARGET_OS) CC=$(CC) BUILDDIR=$(BUILD_DIR)/mdnsd $(TARGET_OPTS)

priv/sbin/mdnsd: $(BUILD_DIR)/mdnsd/mdnsd
	mkdir -p priv/sbin
	# Do a simple copy, since we do not want the initd script copied as well
	cp $^ $@

##
# The port driver
#

$(BUILD_DRV_DIR)/libdns_sd.so.1: $(BUILD_DIR)/mDNSResponder-$(VERSION)
	make -C $(BUILD_DIR)/mDNSResponder-$(VERSION)/mDNSPosix libdns_sd os=$(TARGET_OS) CC=$(CC) BUILDDIR=$(BUILD_DRV_DIR) OBJDIR=$(BUILD_DRV_DIR)

$(BUILD_DRV_DIR)/dnssd.o: c_src/dnssd.c
	env
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -I $(BUILD_DIR)/mDNSResponder-$(VERSION)/mDNSShared -o $@ $<

priv/dnssd_drv.so: $(BUILD_DRV_DIR)/dnssd.o $(CLIENTLIBOBJS)
	$(LD) $+ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

clean:
	rm -rf $(BUILD_DIR)
