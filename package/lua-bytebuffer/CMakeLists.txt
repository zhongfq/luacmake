cmake_minimum_required(VERSION 3.25)

project(lua-bytebuffer)

set(BYTEBUFFER_SRC
    ${LUACMAKE_SOURCE_DIR}/lua-bytebuffer.c
)

add_library(bytebuffer MODULE ${BYTEBUFFER_SRC})
set_target_properties(bytebuffer PROPERTIES PREFIX "")
target_include_directories(bytebuffer PUBLIC ${LUA_INCLUDE_DIR})

if(APPLE)
    target_link_options(bytebuffer PUBLIC -bundle -undefined dynamic_lookup)
elseif(WIN32)
    target_link_libraries(bytebuffer liblua)
endif()