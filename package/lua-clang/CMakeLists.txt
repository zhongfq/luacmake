cmake_minimum_required(VERSION 3.20)

# llvm-project/llvm/CMakeLists.txt
set(LLVM_ENABLE_PROJECTS "clang" CACHE STRING "")
set(LLVM_TARGETS_TO_BUILD "" CACHE STRING "")

# llvm-project/clang/tools/libclang/CMakeLists.txt
set(LIBCLANG_BUILD_STATIC ON CACHE BOOL "")
if(WIN32)
    add_definitions(-D_CINDEX_LIB_)
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -Od")
    set(ENABLE_STATIC STATIC CACHE UNINITIALIZED "")
endif()

add_subdirectory(${LUACMAKE_SOURCE_DIR}/llvm-project/llvm llvm)

set(LUACMAKE_TARGET luaclang)

set(LUACMAKE_SOURCES
    ${LUACMAKE_SOURCE_DIR}/src/lua_clang.h
    ${LUACMAKE_SOURCE_DIR}/src/lua_clang.cpp
    ${LUACMAKE_SOURCE_DIR}/src/clang_wrapper.h
    ${LUACMAKE_SOURCE_DIR}/src/clang_wrapper.cpp
    ${LUACMAKE_SOURCE_DIR}/olua/olua.h
    ${LUACMAKE_SOURCE_DIR}/olua/olua.c
)

add_library(${LUACMAKE_TARGET} MODULE ${LUACMAKE_SOURCES})
set_target_properties(${LUACMAKE_TARGET}
  PROPERTIES
    PREFIX ""
    OUTPUT_NAME clang
)
target_link_libraries(luaclang libclang_static)
target_include_directories(${LUACMAKE_TARGET}
  PUBLIC
    ${LUA_INCLUDE_DIR}
    ${LUACMAKE_SOURCE_DIR}
    ${LUACMAKE_SOURCE_DIR}/llvm-project/clang/include
)

if(APPLE)
    target_link_options(${LUACMAKE_TARGET} PUBLIC -bundle -undefined dynamic_lookup)
elseif(WIN32)
    target_link_libraries(${LUACMAKE_TARGET} liblua)
    target_compile_definitions(${LUACMAKE_TARGET}
      PRIVATE
        LUA_BUILD_AS_DLL
        LUA_LIB
    )
    set_target_properties(libclang_static PROPERTIES OUTPUT_NAME libclang_static)
endif()
