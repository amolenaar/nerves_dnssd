# Variables to override
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_LIBDIR path to libei.a
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries

LDFLAGS +=
CFLAGS += 
CC ?= $(CROSSCOMPILER)gcc

# mDNSResponder version
VERSION = 765.50.9
TARGET_OS ?= linux

.PHONY: all clean daemon lib

all: daemon lib

daemon: priv/sbin/mdnsd
	echo $^ installed

lib: priv/lib/libdns_sd.so.1
	echo $^ installed

deps/mDNSResponder-$(VERSION).tar.gz:
	curl https://opensource.apple.com/tarballs/mDNSResponder/mDNSResponder-$(VERSION).tar.gz -o deps/mDNSResponder-$(VERSION).tar.gz --create-dirs

deps/mDNSResponder-$(VERSION): deps/mDNSResponder-$(VERSION).tar.gz
	tar xzf deps/mDNSResponder-$(VERSION).tar.gz -C deps

deps/mDNSResponder-$(VERSION)/mDNSPosix/build/prod/mdnsd: deps/mDNSResponder-$(VERSION)
	make -C deps/mDNSResponder-$(VERSION)/mDNSPosix Daemon os=$(TARGET_OS)

priv/sbin/mdnsd: deps/mDNSResponder-$(VERSION)/mDNSPosix/build/prod/mdnsd
	mkdir -p priv/sbin
	# Do a simple copy, since we do not want the initd script copied as well
	cp $^ $@

deps/mDNSResponder-$(VERSION)/mDNSPosix/build/prod/libdns_sd.so.1: deps/mDNSResponder-$(VERSION)
	make -C deps/mDNSResponder-$(VERSION)/mDNSPosix libdns_sd os=$(TARGET_OS)

priv/lib/libdns_sd.so.1: deps/mDNSResponder-$(VERSION)/mDNSPosix/build/prod/libdns_sd.so.1
	mkdir -p priv/lib
	mkdir -p priv/include
	make -C deps/mDNSResponder-$(VERSION)/mDNSPosix InstalledLib os=$(TARGET_OS) INSTBASE=$(abspath priv)

clean:
	rm -rf deps/mDNSResponder-$(VERSION) priv
