cmake_minimum_required(VERSION 3.25)

project(lua-cjson)

set(CJSON_SRC
    ${LUACMAKE_SOURCE_DIR}/lua_cjson.c
    ${LUACMAKE_SOURCE_DIR}/strbuf.c
    ${LUACMAKE_SOURCE_DIR}/strbuf.h
)

if(NOT USE_INTERNAL_FPCONV)
    list(APPEND CJSON_SRC
        ${LUACMAKE_SOURCE_DIR}/fpconv.h
        ${LUACMAKE_SOURCE_DIR}/fpconv.c
    )
else()
    add_definitions(-DUSE_INTERNAL_FPCONV)
    list(APPEND CJSON_SRC
        ${LUACMAKE_SOURCE_DIR}/dtoa_config.h.c
        ${LUACMAKE_SOURCE_DIR}/dtoa.c
        ${LUACMAKE_SOURCE_DIR}/g_fmt.c
    )
endif()

add_library(cjson MODULE ${CJSON_SRC})
set_target_properties(cjson PROPERTIES PREFIX "")
target_include_directories(cjson PUBLIC ${LUA_INCLUDE_DIR})

if(APPLE)
    target_link_options(cjson PUBLIC -bundle -undefined dynamic_lookup)
elseif(WIN32)
    target_link_libraries(cjson liblua)
endif()