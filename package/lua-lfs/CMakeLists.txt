cmake_minimum_required(VERSION 3.25)

project(lua-lfs)

set(LFS_SRC
    ${LUACMAKE_SOURCE_DIR}/src/lfs.c
    ${LUACMAKE_SOURCE_DIR}/src/lfs.h
    ${LUACMAKE_SOURCE_DIR}/src/lfs.def
)

add_library(lfs MODULE ${LFS_SRC})
set_target_properties(lfs PROPERTIES PREFIX "")
target_include_directories(lfs PUBLIC ${LUA_INCLUDE_DIR})

if(APPLE)
    target_link_options(lfs PUBLIC -bundle -undefined dynamic_lookup)
elseif(WIN32)
    target_link_libraries(lfs liblua)
endif()