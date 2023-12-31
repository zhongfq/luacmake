cmake_minimum_required(VERSION 3.25)

project(lua-xlsx)

set(CMAKE_CXX_STANDARD 11)

set(BUILD_SHARED_LIBS OFF)

if(APPLE)
    set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
endif()

# -----------------------------------------------------------------------------
# ------------------------------------ lxp ------------------------------------
# -----------------------------------------------------------------------------
set(LXP_DIR ${LUACMAKE_SOURCE_DIR}/luaexpat/src)
add_subdirectory(${LUACMAKE_SOURCE_DIR}/libexpat/expat libexpat)
if(LINUX)
    target_compile_options(expat PRIVATE -fPIC)
endif()
set(LXP_SRC
    ${LXP_DIR}/lxplib.c
    ${LXP_DIR}/lxplib.h
    ${LXP_DIR}/lxp.def
)
add_library(lxp ${LXP_SRC})
set_target_properties(lxp PROPERTIES PREFIX "")
target_include_directories(lxp 
  PUBLIC
    ${LUA_INCLUDE_DIR}
)
target_link_libraries(lxp expat)

# -----------------------------------------------------------------------------
# ----------------------------------- luazip ----------------------------------
# -----------------------------------------------------------------------------
# generate _config.h
include(CheckIncludeFiles)
include(CheckFunctionExists)
include(CheckSymbolExists)
include(CheckTypeSize)
include(TestBigEndian)
include(GNUInstallDirs)
include(CheckCompilerFlag)

check_include_files(byteswap.h ZZIP_HAVE_BYTESWAP_H)
check_include_files(direct.h ZZIP_HAVE_DIRECT_H)

if(NOT ANDROID)
    check_include_files(dirent.h ZZIP_HAVE_DIRENT_H)
endif()

check_include_files(dlfcn.h ZZIP_HAVE_DLFCN_H)
check_include_files(fnmatch.h ZZIP_HAVE_FNMATCH_H)
check_include_files(inttypes.h ZZIP_HAVE_INTTYPES_H)
check_include_files(io.h ZZIP_HAVE_IO_H)
check_include_files(memory.h ZZIP_HAVE_MEMORY_H)
check_include_files(ndir.h ZZIP_HAVE_NDIR_H)
check_include_files(stdint.h ZZIP_HAVE_STDINT_H)
check_include_files(stdlib.h ZZIP_HAVE_STDLIB_H)
check_function_exists(strcasecmp ZZIP_HAVE_STRCASECMP)
check_include_files(strings.h ZZIP_HAVE_STRINGS_H)
check_include_files(string.h ZZIP_HAVE_STRING_H)
check_function_exists(strndup ZZIP_HAVE_STRNDUP)
check_include_files("sys/dir.h" ZZIP_HAVE_SYS_DIR_H)
check_include_files("sys/int_types.h" ZZIP_HAVE_SYS_INT_TYPES_H)
check_include_files("sys/mman.h" ZZIP_HAVE_SYS_MMAN_H)
check_include_files("sys/ndir.h" ZZIP_HAVE_SYS_NDIR_H)
check_include_files("sys/param.h" ZZIP_HAVE_SYS_PARAM_H)
check_include_files("sys/stat.h" ZZIP_HAVE_SYS_STAT_H)
check_include_files("sys/types.h" ZZIP_HAVE_SYS_TYPES_H)
check_include_files(unistd.h ZZIP_HAVE_UNISTD_H)
check_function_exists(pread ZZIP_HAVE_PREAD)
check_include_files(winbase.h ZZIP_HAVE_WINBASE_H)
check_include_files(windows.h ZZIP_HAVE_WINDOWS_H)
check_include_files(winnt.h ZZIP_HAVE_WINNT_H)
set(ZZIP_HAVE_ZLIB_H 1)

check_type_size(int ZZIP_SIZEOF_INT)
check_type_size(long ZZIP_SIZEOF_LONG)
check_type_size(short ZZIP_SIZEOF_SHORT)
check_include_files("stdlib.h;stdarg.h;string.h;float.h" ZZIP_STDC_HEADERS)
test_big_endian(ZZIP_WORDS_BIGENDIAN)

# simplified largefile support detection for unix
set(CMAKE_REQUIRED_DEFINITIONS -D_LARGEFILE_SOURCE -Doff_t_32=off_t)
check_type_size( off_t_32 ZZIP_SIZEOF_OFF_T_32)
set(CMAKE_REQUIRED_DEFINITIONS -D_LARGEFILE_SOURCE -Doff_t_64=off_t -D_FILE_OFFSET_BITS=64 -D_LARGE_FILES)
check_type_size( off_t_64 ZZIP_SIZEOF_OFF_T_64)
set(CMAKE_REQUIRED_DEFINITIONS -D_LARGEFILE64_SOURCE)
check_type_size( off64_t ZZIP_SIZEOF_OFF64_T)

if(ZZIP_SIZEOF_OFF_T_32)
  message(STATUS "found sizeof(off_t/32)=${ZZIP_SIZEOF_OFF_T_32} and sizeof(off_t/64)=${ZZIP_SIZEOF_OFF_T_64}")
  if(NOT ZZIP_SIZEOF_OFF_T_32 EQUAL ZZIP_SIZEOF_OFF_T_64)
    set(ZZIP_LARGEFILE_SENSITIVE 1)
    # this will turn into ZZIP_LARGEFILE_RENAME so that zzip_opendir becomes zzip_opendir64 in the lib
    # which is needed on Linux/Solaris where the default zzip_opendir is expected to use a 32bit off_t
    message(STATUS "system is large file sensitive - do rename symbols to xx64")
    set(largefiles -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGE_FILES)
  endif()
endif()

configure_file (
    ${LUACMAKE_SOURCE_DIR}/zziplib/zzip/_config.h.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/zzip/_config.h
)

# Zlib library needed
add_subdirectory(${LUACMAKE_SOURCE_DIR}/zlib zlib)
target_include_directories(zlib
  PUBLIC
    ${LUACMAKE_SOURCE_DIR}/zlib
)
target_include_directories(zlibstatic
  PUBLIC
    ${LUACMAKE_SOURCE_DIR}/zlib
)

if(UNIX)
    CHECK_COMPILER_FLAG(C "-Warray-bounds" HAS_WARRAY_BOUNDS)
    add_definitions(
        -Wpointer-arith
        -Wsign-compare
        -Wmissing-declarations
        # -Wdeclaration-after-statement
        -Werror-implicit-function-declaration
        -Wstrict-aliasing
    )
    if(HAS_WARRAY_BOUNDS)
        add_definitions(
            -Warray-bounds
        )
  endif()
endif()

# set(CMAKE_POSITION_INDEPENDENT_CODE ${BUILD_SHARED_LIBS})
add_definitions(-DHAVE_CONFIG_H)
set(LIBZZIP_DIR ${LUACMAKE_SOURCE_DIR}/zziplib/zzip)
set(LIBZZIP_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/zzip)

# libzlib library
set(LIBZZIP_SRCS 
    ${LIBZZIP_DIR}/dir.c
    ${LIBZZIP_DIR}/err.c 
    ${LIBZZIP_DIR}/file.c 
    ${LIBZZIP_DIR}/info.c 
    ${LIBZZIP_DIR}/plugin.c 
    ${LIBZZIP_DIR}/stat.c
    ${LIBZZIP_DIR}/write.c 
    ${LIBZZIP_DIR}/zip.c 
    ${LIBZZIP_DIR}/fetch.c
)

set(LIBZZIP_HDRS
    ${LIBZZIP_DIR}/lib.h
    ${LIBZZIP_DIR}/zzip.h
    ${LIBZZIP_DIR}/format.h
    ${LIBZZIP_DIR}/types.h
    ${LIBZZIP_DIR}/conf.h 
    ${LIBZZIP_DIR}/_msvc.h 
    ${LIBZZIP_DIR}/file.h
    ${LIBZZIP_DIR}/info.h
    ${LIBZZIP_DIR}/plugin.h
    ${LIBZZIP_DIR}/write.h
    ${LIBZZIP_DIR}/fetch.h
    ${LIBZZIP_DIR}/stdint.h
    ${LIBZZIP_DIR}/zzip32.h
    ${LIBZZIP_DIR}/autoconf.h
    ${LIBZZIP_BINARY_DIR}/_config.h)

set(libzzip_INCS
    __debug.h
    __dirent.h
    __errno.h
    __fnmatch.h
    __hints.h
    __mkdir.h
    __mmap.h
    __string.h)


add_library(libzzip ${LIBZZIP_SRCS})
if(WIN32)
    target_link_libraries(libzzip zlibstatic)
else()
    target_link_libraries(libzzip zlib)
endif()
target_include_directories(libzzip
  PUBLIC
    ${CMAKE_CURRENT_BINARY_DIR}
    ${LUACMAKE_SOURCE_DIR}/zziplib
    ${LUACMAKE_SOURCE_DIR}/zlib
    ${CMAKE_CURRENT_BINARY_DIR}/zlib
)

set(LUAZIP_DIR ${LUACMAKE_SOURCE_DIR}/luazip)
set(LUAZIP_SRC
    ${LUAZIP_DIR}/src/luazip.c
    ${LUAZIP_DIR}/src/luazip.h
    ${LUAZIP_DIR}/src/luazip.def
)
add_library(zip ${LUAZIP_SRC})
target_link_libraries(zip libzzip)
set_target_properties(zip PROPERTIES PREFIX "")
target_include_directories(zip PUBLIC ${LUA_INCLUDE_DIR})


# -----------------------------------------------------------------------------
# ------------------------------------ xlsx -----------------------------------
# -----------------------------------------------------------------------------
set(XLSX_SRC
   ${LUACMAKE_SOURCE_DIR}/lua-xlsx.cpp
)
add_library(xlsx MODULE ${XLSX_SRC})
target_link_libraries(xlsx zip lxp olua)
set_target_properties(xlsx PROPERTIES PREFIX "")
target_include_directories(xlsx
  PUBLIC
    ${LUA_INCLUDE_DIR}
    ${LUACMAKE_SOURCE_DIR}/luaexpat/src
    ${LUACMAKE_SOURCE_DIR}/luazip/src
)
if(APPLE)
    target_link_options(xlsx PUBLIC -bundle -undefined dynamic_lookup)
elseif(WIN32)
    target_link_libraries(xlsx liblua)
endif()