cmake_minimum_required(VERSION 3.20)

set(LUACMAKE_TARGET lpeg)

set(LUACMAKE_SOURCES
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