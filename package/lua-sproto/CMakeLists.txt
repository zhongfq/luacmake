cmake_minimum_required(VERSION 3.20)

set(LUACMAKE_TARGET sproto)

set(LUACMAKE_SOURCES
    ${LUACMAKE_SOURCE_DIR}/lsproto.c
    ${LUACMAKE_SOURCE_DIR}/msvcint.h
    ${LUACMAKE_SOURCE_DIR}/sproto.c
    ${LUACMAKE_SOURCE_DIR}/sproto.h
    ${CMAKE_CURRENT_SOURCE_DIR}/lua-sproto.cpp
)

add_library(${LUACMAKE_TARGET} MODULE ${LUACMAKE_SOURCES})
set_target_properties(${LUACMAKE_TARGET} PROPERTIES PREFIX "")
target_include_directories(${LUACMAKE_TARGET}
  PUBLIC
    ${LUA_INCLUDE_DIR}
    ${LUACMAKE_SOURCE_DIR}
)

if(APPLE)
    target_link_options(${LUACMAKE_TARGET} PUBLIC -bundle -undefined dynamic_lookup)
elseif(WIN32)
    target_link_libraries(${LUACMAKE_TARGET} liblua)
    target_compile_definitions(${LUACMAKE_TARGET}
      PRIVATE
        LUA_BUILD_AS_DLL
    )
endif()