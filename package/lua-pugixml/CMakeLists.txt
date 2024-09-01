cmake_minimum_required(VERSION 3.20)

set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(LUACMAKE_TARGET libpugixml)

set(LUACMAKE_SOURCES
    ${LUACMAKE_SOURCE_DIR}/src/lua_pugixml.h
    ${LUACMAKE_SOURCE_DIR}/src/lua_pugixml.cpp
    ${LUACMAKE_SOURCE_DIR}/olua/olua.h
    ${LUACMAKE_SOURCE_DIR}/olua/olua.c
)

add_subdirectory(${LUACMAKE_SOURCE_DIR}/pugixml pugixml)

add_library(${LUACMAKE_TARGET} MODULE ${LUACMAKE_SOURCES})
set_target_properties(${LUACMAKE_TARGET}
  PROPERTIES
    PREFIX ""
    OUTPUT_NAME pugixml
)
target_link_libraries(${LUACMAKE_TARGET} pugixml-static)
target_include_directories(${LUACMAKE_TARGET} 
  PUBLIC
    ${LUA_INCLUDE_DIR}
    ${LUACMAKE_SOURCE_DIR}
    ${LUACMAKE_SOURCE_DIR}/olua
)

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