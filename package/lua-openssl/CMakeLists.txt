cmake_minimum_required(VERSION 3.20)

set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH}
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules")
option(BUILD_SHARED_LUA_OPENSSL "Shared or Static lua-openssl" ON)

include(GNUInstallDirs)

set(OPENSSL_SRC_DIR ${LUACMAKE_SOURCE_DIR}/openssl)
add_subdirectory(${LUACMAKE_SOURCE_DIR}/openssl-cmake openssl-cmake)

set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)

if(BUILD_SHARED_LUA_OPENSSL)
    if(WIN32)
        add_definitions(-DLUA_BUILD_AS_DLL)
        set(EXTRA_LIBS "ws2_32.lib" "crypt32.lib")
    endif()
endif()

set(LUACMAKE_SOURCES
    ${LUACMAKE_SOURCE_DIR}/deps/auxiliar/auxiliar.c
    ${LUACMAKE_SOURCE_DIR}/deps/auxiliar/subsidiar.c
    ${LUACMAKE_SOURCE_DIR}/src/asn1.c
    ${LUACMAKE_SOURCE_DIR}/src/bio.c
    ${LUACMAKE_SOURCE_DIR}/src/callback.c
    ${LUACMAKE_SOURCE_DIR}/src/cipher.c
    ${LUACMAKE_SOURCE_DIR}/src/cms.c
    ${LUACMAKE_SOURCE_DIR}/src/compat.c
    ${LUACMAKE_SOURCE_DIR}/src/crl.c
    ${LUACMAKE_SOURCE_DIR}/src/csr.c
    ${LUACMAKE_SOURCE_DIR}/src/dh.c
    ${LUACMAKE_SOURCE_DIR}/src/digest.c
    ${LUACMAKE_SOURCE_DIR}/src/dsa.c
    ${LUACMAKE_SOURCE_DIR}/src/ec.c
    ${LUACMAKE_SOURCE_DIR}/src/engine.c
    ${LUACMAKE_SOURCE_DIR}/src/mac.c
    ${LUACMAKE_SOURCE_DIR}/src/hmac.c
    ${LUACMAKE_SOURCE_DIR}/src/kdf.c
    ${LUACMAKE_SOURCE_DIR}/src/lbn.c
    ${LUACMAKE_SOURCE_DIR}/src/lhash.c
    ${LUACMAKE_SOURCE_DIR}/src/misc.c
    ${LUACMAKE_SOURCE_DIR}/src/ocsp.c
    ${LUACMAKE_SOURCE_DIR}/src/oids.txt
    ${LUACMAKE_SOURCE_DIR}/src/openssl.c
    ${LUACMAKE_SOURCE_DIR}/src/ots.c
    ${LUACMAKE_SOURCE_DIR}/src/param.c
    ${LUACMAKE_SOURCE_DIR}/src/pkcs12.c
    ${LUACMAKE_SOURCE_DIR}/src/pkcs7.c
    ${LUACMAKE_SOURCE_DIR}/src/pkey.c
    ${LUACMAKE_SOURCE_DIR}/src/private.h
    ${LUACMAKE_SOURCE_DIR}/src/rsa.c
    ${LUACMAKE_SOURCE_DIR}/src/sk.h
    ${LUACMAKE_SOURCE_DIR}/src/srp.c
    ${LUACMAKE_SOURCE_DIR}/src/ssl.c
    ${LUACMAKE_SOURCE_DIR}/src/th-lock.c
    ${LUACMAKE_SOURCE_DIR}/src/util.c
    ${LUACMAKE_SOURCE_DIR}/src/x509.c
    ${LUACMAKE_SOURCE_DIR}/src/xattrs.c
    ${LUACMAKE_SOURCE_DIR}/src/xexts.c
    ${LUACMAKE_SOURCE_DIR}/src/xname.c
    ${LUACMAKE_SOURCE_DIR}/src/xalgor.c
    ${LUACMAKE_SOURCE_DIR}/src/xstore.c
)

olua_add_library(lua-openssl
  ${LUACMAKE_SOURCES}

  OUTPUT_NAME "openssl"

  LINK_LIBS
    ssl
    crypto
    ${EXTRA_LIBS}
    Threads::Threads

  INCLUDE_DIRS
    ${LUACMAKE_SOURCE_DIR}/deps
    ${LUACMAKE_SOURCE_DIR}/deps/lua-compat/c-api
    ${LUACMAKE_SOURCE_DIR}/deps/auxiliar
)
