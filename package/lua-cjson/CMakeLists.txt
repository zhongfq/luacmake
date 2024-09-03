cmake_minimum_required(VERSION 3.20)

set(LUACMAKE_SOURCES
    ${LUACMAKE_SOURCE_DIR}/lua_cjson.c
    ${LUACMAKE_SOURCE_DIR}/strbuf.c
    ${LUACMAKE_SOURCE_DIR}/strbuf.h
)

if(NOT USE_INTERNAL_FPCONV)
    list(APPEND LUACMAKE_SOURCES
        ${LUACMAKE_SOURCE_DIR}/fpconv.h
        ${LUACMAKE_SOURCE_DIR}/fpconv.c
    )
else()
    add_definitions(-DUSE_INTERNAL_FPCONV)
    list(APPEND LUACMAKE_SOURCES
        ${LUACMAKE_SOURCE_DIR}/dtoa_config.h.c
        ${LUACMAKE_SOURCE_DIR}/dtoa.c
        ${LUACMAKE_SOURCE_DIR}/g_fmt.c
    )
endif()

olua_add_library(cjson ${LUACMAKE_SOURCES})
