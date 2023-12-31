cmake_minimum_required(VERSION 3.10)

project(olua)

set(OLUA_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../olua)

set(OLUA_SRC
    ${OLUA_SOURCE_DIR}/olua.c
    ${OLUA_SOURCE_DIR}/olua.h
    ${OLUA_SOURCE_DIR}/olua.hpp
)

add_library(olua STATIC ${OLUA_SRC})
target_include_directories(olua
  PUBLIC
    ${OLUA_SOURCE_DIR}
    ${LUA_INCLUDE_DIR}
)