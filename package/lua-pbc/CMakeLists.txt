cmake_minimum_required(VERSION 3.20)

set(LUACMAKE_TARGET protobuf)
set(CMAKE_CXX_STANDARD 11)

set(LUACMAKE_SOURCES
    ${LUACMAKE_SOURCE_DIR}/src/alloc.c
    ${LUACMAKE_SOURCE_DIR}/src/alloc.h
    ${LUACMAKE_SOURCE_DIR}/src/array.c
    ${LUACMAKE_SOURCE_DIR}/src/array.h
    ${LUACMAKE_SOURCE_DIR}/src/bootstrap.c
    ${LUACMAKE_SOURCE_DIR}/src/bootstrap.h
    ${LUACMAKE_SOURCE_DIR}/src/context.c
    ${LUACMAKE_SOURCE_DIR}/src/context.h
    ${LUACMAKE_SOURCE_DIR}/src/decode.c
    ${LUACMAKE_SOURCE_DIR}/src/descriptor.pbc.h
    ${LUACMAKE_SOURCE_DIR}/src/map.c
    ${LUACMAKE_SOURCE_DIR}/src/map.h
    ${LUACMAKE_SOURCE_DIR}/src/packet.c
    ${LUACMAKE_SOURCE_DIR}/src/packet.h
    ${LUACMAKE_SOURCE_DIR}/src/pattern.c
    ${LUACMAKE_SOURCE_DIR}/src/pattern.h
    ${LUACMAKE_SOURCE_DIR}/src/pbc-lua53.c
    ${LUACMAKE_SOURCE_DIR}/src/pbc.h
    ${LUACMAKE_SOURCE_DIR}/src/proto.c
    ${LUACMAKE_SOURCE_DIR}/src/proto.h
    ${LUACMAKE_SOURCE_DIR}/src/register.c
    ${LUACMAKE_SOURCE_DIR}/src/rmessage.c
    ${LUACMAKE_SOURCE_DIR}/src/stringpool.c
    ${LUACMAKE_SOURCE_DIR}/src/stringpool.h
    ${LUACMAKE_SOURCE_DIR}/src/varint.c
    ${LUACMAKE_SOURCE_DIR}/src/varint.h
    ${LUACMAKE_SOURCE_DIR}/src/wmessage.c
    lua-protobuf.cpp
)

add_library(${LUACMAKE_TARGET} MODULE ${LUACMAKE_SOURCES})
set_target_properties(${LUACMAKE_TARGET} PROPERTIES PREFIX "")
target_include_directories(${LUACMAKE_TARGET}
  PUBLIC
    ${LUA_INCLUDE_DIR}
    ${LUACMAKE_SOURCE_DIR}/src
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
endif()
