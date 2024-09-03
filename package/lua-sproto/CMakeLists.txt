cmake_minimum_required(VERSION 3.20)

set(CMAKE_CXX_STANDARD 11)

olua_add_library(sproto
  ${LUACMAKE_SOURCE_DIR}/lsproto.c
  ${LUACMAKE_SOURCE_DIR}/msvcint.h
  ${LUACMAKE_SOURCE_DIR}/sproto.c
  ${LUACMAKE_SOURCE_DIR}/sproto.h
  ${CMAKE_CURRENT_SOURCE_DIR}/lua-sproto.cpp
)