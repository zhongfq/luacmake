cmake_minimum_required(VERSION 3.20)

olua_add_library(lfs
  ${LUACMAKE_SOURCE_DIR}/src/lfs.c
  ${LUACMAKE_SOURCE_DIR}/src/lfs.h
  ${LUACMAKE_SOURCE_DIR}/src/lfs.def
)