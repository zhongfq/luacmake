cmake_minimum_required(VERSION 3.20)

# llvm-project/llvm/CMakeLists.txt
set(LLVM_ENABLE_PROJECTS "clang" CACHE STRING "")
set(LLVM_TARGETS_TO_BUILD "" CACHE STRING "")
set(LLVM_ENABLE_ZSTD "OFF" CACHE STRING "")

# llvm-project/clang/tools/libclang/CMakeLists.txt
set(LIBCLANG_BUILD_STATIC ON CACHE BOOL "")
if(WIN32)
    add_definitions(-D_CINDEX_LIB_)
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -Od")
    set(ENABLE_STATIC STATIC CACHE UNINITIALIZED "")
endif()

add_subdirectory(${LUACMAKE_SOURCE_DIR}/llvm-project/llvm llvm)

olua_add_library(luaclang
  ${LUACMAKE_SOURCE_DIR}/src/lua_clang.h
  ${LUACMAKE_SOURCE_DIR}/src/lua_clang.cpp
  ${LUACMAKE_SOURCE_DIR}/src/clang_wrapper.h
  ${LUACMAKE_SOURCE_DIR}/src/clang_wrapper.cpp
  ${LUACMAKE_SOURCE_DIR}/olua/olua.h
  ${LUACMAKE_SOURCE_DIR}/olua/olua.c

  OUTPUT_NAME
    clang
  
  LINK_LIBS
    libclang_static

  INCLUDE_DIRS
    ${LUACMAKE_SOURCE_DIR}/llvm-project/clang/include
)
