cmake_minimum_required(VERSION 3.25)

set(LUACMAKE_TARGET lfs)

set(LUACMAKE_SOURCES
    ${LUACMAKE_SOURCE_DIR}/src/lfs.c
    ${LUACMAKE_SOURCE_DIR}/src/lfs.h
    ${LUACMAKE_SOURCE_DIR}/src/lfs.def
)

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