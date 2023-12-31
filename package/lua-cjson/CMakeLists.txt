cmake_minimum_required(VERSION 3.25)

set(LUACMAKE_TARGET cjson)

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

add_library(${LUACMAKE_TARGET} MODULE ${LUACMAKE_SOURCES})
set_target_properties(${LUACMAKE_TARGET} PROPERTIES PREFIX "")
target_include_directories(${LUACMAKE_TARGET} PUBLIC ${LUA_INCLUDE_DIR})

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