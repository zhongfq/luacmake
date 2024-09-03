function (olua_add_library name)
  cmake_parse_arguments(ARG "" "OUTPUT_NAME" "INCLUDE_DIRS;LINK_LIBS" ${ARGN})
  add_library(${name} MODULE ${ARG_UNPARSED_ARGUMENTS})
  if(ARG_OUTPUT_NAME)
    set_target_properties(${name} PROPERTIES OUTPUT_NAME ${ARG_OUTPUT_NAME}
  )
  endif()
  target_include_directories(${name}
    PUBLIC
      ${ARG_INCLUDE_DIRS}
      ${LUA_INCLUDE_DIR}
      ${LUACMAKE_SOURCE_DIR}
      ${LUACMAKE_SOURCE_DIR}/olua
  )
  target_link_libraries(${name} ${ARG_LINK_LIBS})
  set_target_properties(${name} PROPERTIES PREFIX "")
  if(APPLE)
    target_link_options(${name} PUBLIC -bundle -undefined dynamic_lookup)
  elseif(WIN32)
    target_link_libraries(${name} liblua)
    target_compile_definitions(${name}
      PRIVATE
      LUA_BUILD_AS_DLL
      LUA_LIB
    )
  endif()
endfunction()