cmake_minimum_required(VERSION 3.20)

set(CMAKE_CXX_STANDARD 11)

olua_add_library(lpeg
  ${LUACMAKE_SOURCE_DIR}/lpcap.c
  ${LUACMAKE_SOURCE_DIR}/lpcap.h
  ${LUACMAKE_SOURCE_DIR}/lpcode.c
  ${LUACMAKE_SOURCE_DIR}/lpcode.h
  ${LUACMAKE_SOURCE_DIR}/lpcset.c
  ${LUACMAKE_SOURCE_DIR}/lpcset.h
  ${LUACMAKE_SOURCE_DIR}/lpprint.c
  ${LUACMAKE_SOURCE_DIR}/lpprint.h
  ${LUACMAKE_SOURCE_DIR}/lptree.c
  ${LUACMAKE_SOURCE_DIR}/lptree.h
  ${LUACMAKE_SOURCE_DIR}/lptypes.h
  ${LUACMAKE_SOURCE_DIR}/lpvm.c
  ${LUACMAKE_SOURCE_DIR}/lpvm.h
  ${CMAKE_CURRENT_SOURCE_DIR}/lua-re.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/lpeg.def
)
