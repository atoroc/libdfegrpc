SRC = libdfegrpc.cc
OBJS = $(SRC:.cc=.oo)
TARGET_LIB = libdfegrpc.so

CFLAGS = -g -Wall -O0 -DBUILDING_LIBDFEGRPC
CXXFLAGS = -std=c++11 -fPIC -I. -Iprotos -Wall -g -O0 -DBUILDING_LIBDFEGRPC
LDFLAGS = -shared

VERSION ?= $(shell git describe --tags --dirty=M 2> /dev/null | sed -e 's/[^/]*\///g' -e 's/-/_/g')
GRPC_VERSION ?= 1.12.1

GOOGLE_TEST_VERSION = release-1.8.0
GOOGLE_TEST_ARCHIVE = $(GOOGLE_TEST_VERSION).zip
GOOGLE_TEST_ARCHIVE_URI = https://github.com/google/googletest/archive/$(GOOGLE_TEST_ARCHIVE)

GOOGLE_TEST_FLAGS = -isystem googletest-$(GOOGLE_TEST_VERSION)/googlemock/include \
		-isystem googletest-$(GOOGLE_TEST_VERSION)/googletest/include \
		-Igoogletest-$(GOOGLE_TEST_VERSION)/googlemock \
		-Igoogletest-$(GOOGLE_TEST_VERSION)/googletest -pthread

.PHONY: all
all: proto-ccs $(TARGET_LIB)

include Makefile.protos

.PHONY: test
test: test_client test_synth

.PHONY: proto-ccs
proto-ccs: $(PROTOCCS)

libdfegrpc.a: $(PROTOOBJS) $(OBJS)
	$(AR) rcs $@ $^

libdfegrpc.oo: libdfegrpc.cc libdfegrpc.h libdfegrpc_internal.h

$(TARGET_LIB): $(PROTOOBJS) $(OBJS)
	$(CXX) $(LDFLAGS) -o $@ $^ -lgrpc++ -lprotobuf -lgrpc

# LD_LIBRARY_PATH=/usr/local/lib:. ./test_client
test_client: test_client.o
	$(CC) -g -o $@ test_client.o -ldfegrpc -lgrpc++ -lprotobuf -lpthread -lstdc++

test_client2: test_client2.oo $(PROTOOBJS)
	$(CXX) -g -o $@ test_client2.oo -ldfegrpc -lgrpc++ -lprotobuf -lpthread -lstdc++ -lgrpc

test_synth: test_synth.o
	$(CC) -g -o $@ test_synth.o -ldfegrpc -lgrpc++ -lprotobuf -lpthread -lstdc++

.PHONY: clean
clean: 
	rm -Rf $(OBJS) $(PROTOOBJS) test_client test_client.o $(TARGET_LIB)

.PHONY: distclean
distclean: clean
	rm -Rf $(PROTOCCS)

PREFIX ?= /usr

.PHONY: install
install: $(TARGET_LIB)
	install -d $(DESTDIR)$(PREFIX)/lib/
	install -m 644 $(TARGET_LIB) $(DESTDIR)$(PREFIX)/lib/
	install -m 644 libdfegrpc.h $(DESTDIR)$(PREFIX)/include/
	
%.oo: %.cc
	$(CXX) -c -o $@ $(CXXFLAGS) $<

$(GOOGLE_TEST_ARCHIVE):
	wget $(GOOGLE_TEST_ARCHIVE_URI)

googletest-$(GOOGLE_TEST_VERSION)/googletest/src/gtest-all.cc: $(GOOGLE_TEST_ARCHIVE)
	unzip -u $<

gtest-all.oo: googletest-$(GOOGLE_TEST_VERSION)/googletest/src/gtest-all.cc
	$(CXX) -g $(GOOGLE_TEST_FLAGS) -o $@ -c $<

gmock-all.oo: googletest-$(GOOGLE_TEST_VERSION)/googlemock/src/gmock-all.cc
	$(CXX) -g $(GOOGLE_TEST_FLAGS) -o $@ -c $<

libgtest.a: gtest-all.oo gmock-all.oo
	$(AR) -rv $@ $^

google_test_client.oo: google_test_client.cc googletest-$(GOOGLE_TEST_VERSION)/googletest/src/gtest-all.cc
	$(CXX) -c -o $@ -g $(GOOGLE_TEST_FLAGS) $(CXXFLAGS) $<

google_test_client: google_test_client.oo libgtest.a
	$(CXX) -o $@ -g $(GOOGLE_TEST_FLAGS) $^ -ldfegrpc -lgrpc++ -lprotobuf -lpthread -lstdc++

###################
# docker build stuff
###################

RPMS = libgrpc-$(GRPC_VERSION)-1.x86_64.rpm libgrpc-devel-$(GRPC_VERSION)-1.x86_64.rpm libdfegrpc-$(VERSION)-1.x86_64.rpm libdfegrpc-devel-$(VERSION)-1.x86_64.rpm

.PHONY = docker-build
docker-build: $(RPMS)

.build:
	mkdir -p .build

.build/libdfegrpc_build: Dockerfile .build
	docker build --tag libdfegrpc_build:latest .
	@touch "$@"

libgrpc-$(GRPC_VERSION)-1.x86_64.rpm libgrpc-devel-$(GRPC_VERSION)-1.x86_64.rpm: Makefile.grpcdocker .build/libdfegrpc_build
	docker run --rm -v $(CURDIR):/src:ro \
			-v $(CURDIR):/out \
			-w /tmp libdfegrpc_build \
			make -f /src/Makefile.grpcdocker

libdfegrpc-$(VERSION)-1.x86_64.rpm libdfegrpc-devel-$(VERSION)-1.x86_64.rpm: Makefile.dfedocker \
															libgrpc-$(GRPC_VERSION)-1.x86_64.rpm \
															libgrpc-devel-$(GRPC_VERSION)-1.x86_64.rpm \
															.build/libdfegrpc_build
	docker run --rm -v $(CURDIR):/src:ro \
			-e VERSION=$(VERSION) \
			-v $(CURDIR):/out \
			-w /tmp libdfegrpc_build \
			make -f /src/Makefile.dfedocker