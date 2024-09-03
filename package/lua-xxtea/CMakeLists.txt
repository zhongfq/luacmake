cmake_minimum_required(VERSION 3.20)

olua_add_library(xxtea
    ${LUACMAKE_SOURCE_DIR}/src/lua_xxtea.c
    ${LUACMAKE_SOURCE_DIR}/src/xxtea.c
    ${LUACMAKE_SOURCE_DIR}/src/xxtea.h
)
