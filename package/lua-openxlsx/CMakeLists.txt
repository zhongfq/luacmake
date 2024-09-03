cmake_minimum_required(VERSION 3.20)

set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_subdirectory(${LUACMAKE_SOURCE_DIR}/OpenXLSX/OpenXLSX OpenXLSX)

olua_add_library(openxlsx
  ${LUACMAKE_SOURCE_DIR}/src/lua_openxlsx.h
  ${LUACMAKE_SOURCE_DIR}/src/lua_openxlsx.cpp
  ${LUACMAKE_SOURCE_DIR}/olua/olua.h
  ${LUACMAKE_SOURCE_DIR}/olua/olua.c

  LINK_LIBS
    OpenXLSX
)