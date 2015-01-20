#cmake

if(CF_UTILITIES_INCLUDED)
  return()
endif()
set(CF_UTILITIES_INCLUDED ON)

include(CMakeParseArguments)
include(echoTargetProperties)

## logging
########################################################################

# warning ids
set(CF_WARNING_ID_NOT_IMPLEMENTED 0)
set(CF_WARNING_ID_UNPARSED_ARGS   1)

function(cf_generate_log_prefix VERBOSITY OUTPUT_VARIABLE)
  if(CF_SHOW_VERBOSITY_IN_LOG)
    set(${OUTPUT_VARIABLE} "${VERBOSITY})${CF_LOG_PREFIX}" PARENT_SCOPE)
  else()
    set(${OUTPUT_VARIABLE} "${CF_LOG_PREFIX}" PARENT_SCOPE)
  endif()
endfunction()

function(cf_message _VERBOSITY _STATUS _MESSAGE)
  if(NOT _VERBOSITY GREATER CF_VERBOSITY)
    cf_generate_log_prefix(${_VERBOSITY} CF_LOG_PREFIX)
    message(${_STATUS} "${CF_LOG_PREFIX} ${_MESSAGE}")
  endif()
endfunction(cf_message)

function(cf_log _VERBOSITY _MESSAGE)
  if(NOT _VERBOSITY GREATER CF_VERBOSITY)
    cf_generate_log_prefix(${_VERBOSITY} CF_LOG_PREFIX)
    message(STATUS "${CF_LOG_PREFIX} ${_MESSAGE}")
  endif()
endfunction(cf_log)
cf_log(0 "Note: log output for this project is controlled by the advanced cache variable CF_VERBOSITY")

function(cf_error _MESSAGE)
  message(SEND_ERROR "${CF_LOG_PREFIX} ${_MESSAGE}")
endfunction(cf_error)

function(cf_fatal _MESSAGE)
  message(FATAL_ERROR "${CF_LOG_PREFIX} ${_MESSAGE}")
endfunction(cf_fatal)

function(cf_warning _ID _MESSAGE)
  # warnings will only be printed when the global verbosity is 1 or higher
  if(CF_VERBOSITY LESS 1)
    return()
  endif()

  list(FIND "${CF_DISABLED_WARNINGS}" "${_ID}" WARNING_INDEX)
  if(WARNING_INDEX EQUAL -1) # not found
    message(AUTHOR_WARNING "${CF_LOG_PREFIX} ${_MESSAGE}")
  endif()
endfunction(cf_warning)

function(cf_warning_not_implemented)
  cf_warning(${CF_WARNING_ID_NOT_IMPLEMENTED} "[not implemented] ${ARGN}")
endfunction(cf_warning_not_implemented)

function(cf_warning_unparsed_args)
  cf_warning(${CF_WARNING_ID_UNPARSED_ARGS} "[unparsed args] ${ARGN}")
endfunction()

# general config
########################################################################

include(cfConfig)

# helper functions
########################################################################

function(cf_indent_log_prefix INDENT_STRING)
  set(CF_LOG_PREFIX "${CF_LOG_PREFIX}${INDENT_STRING}" PARENT_SCOPE)
endfunction(cf_indent_log_prefix)

function(cf_unindent_log_prefix UNINDENT_AMOUNT)
  string(LENGTH "${CF_LOG_PREFIX}" LEN)
  math(EXPR LEN "${LEN}-${UNINDENT_AMOUNT}")
  string(SUBSTRING "${CF_LOG_PREFIX}" 0  LEN RESULT)
  set(CF_LOG_PREFIX "${RESULT}" PARENT_SCOPE)
endfunction(cf_unindent_log_prefix)

function(cf_msvc_add_pch_flags PCH)
  cf_indent_log_prefix("(pch)")
  cmake_parse_arguments(PCH "" PREFIX "" ${ARGN})

  get_filename_component(PCH_DIR "${PCH}" DIRECTORY)
  get_filename_component(PCH     "${PCH}" NAME_WE)

  if(PCH_PREFIX)
    set(PCH_PREFIX "${PCH_PREFIX}/")
  endif()

  set(PCH_CREATE_FLAG "/Yc${PCH_PREFIX}${PCH}.h")
  set(PCH_USE_FLAG    "/Yu${PCH_PREFIX}${PCH}.h")

  # if the pch is not on the top-level, prepend the directory
  if(NOT PCH_DIR STREQUAL "")
    set(PCH "${PCH_DIR}/${PCH_NAME}")
  endif()

  cf_log(3 "adding source property '${PCH_CREATE_FLAG}': ${PCH}.cpp")
  # add the necessary compiler flags to pch itself
  set_source_files_properties("${PCH}.cpp" PROPERTIES COMPILE_FLAGS "${PCH_CREATE_FLAG}")

  foreach(SRC_FILE ${ARGN})
    # we ignore the precompiled header and the corresponding .cpp file itself
    if(NOT SRC_FILE STREQUAL "${PCH}.h" AND NOT SRC_FILE STREQUAL "${PCH}.cpp")
      get_filename_component(SRC_EXT "${SRC_FILE}" EXT)
      # only apply the 'use' flag on .cpp files
      if("${SRC_EXT}" STREQUAL ".cpp")
        get_filename_component(SRC_NAME "${SRC_FILE}" NAME_WE)
        cf_log(3 "adding source property '${PCH_USE_FLAG}': ${SRC_FILE}")
        set_source_files_properties ("${SRC_FILE}" PROPERTIES COMPILE_FLAGS "${PCH_USE_FLAG}")
      endif()
    endif()
  endforeach()
endfunction(cf_msvc_add_pch_flags)

function(cf_group_sources_by_file_system)
  cf_indent_log_prefix("(source grouping)")
  foreach(SRC_FILE ${ARGN})
    get_filename_component(SRC_DIR "${SRC_FILE}" DIRECTORY)
    string(REPLACE "/" "\\" SRC_DIR "${SRC_DIR}")
    source_group("${SRC_DIR}" FILES "${SRC_FILE}")
    cf_log(3 "${SRC_DIR} => ${SRC_FILE}")
  endforeach()
endfunction(cf_group_sources_by_file_system)

function(cf_add_sfml TARGET_NAME)
  set(SFML_ROOT "$ENV{SFML_ROOT}" CACHE PATH
      "Path to the (installed) SFML root directory. This variable can be set manually if cmake fails to find SFML automatically.")
  find_package(SFML ${ARGN})
  if(SFML_FOUND)
    include_directories("${SFML_INCLUDE_DIR}")
    target_link_libraries(${TARGET_NAME} ${SFML_LIBRARIES})
  else()
    cf_log(0 "Please specify SFML_ROOT as either a cmake cache variable or an environment variable.")
  endif()

  # copy DLLs only on windows
  if(MSVC)
    # copy SFML dlls to output dir as a post-build command
    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                       COMMAND ${CMAKE_COMMAND} -E copy_directory
                       "${SFML_ROOT}/bin"
                       $<TARGET_FILE_DIR:${TARGET_NAME}>)
  endif()
endfunction(cf_add_sfml)

function(cf_add_ezEngine TARGET_NAME)
  cmake_parse_arguments(ezEngine "POST_BUILD_COPY_DLLS" "" "" ${ARGN})
  if(ezEngine_POST_BUILD_COPY_DLLS)
    set(ezEngine_POST_BUILD_COPY_DLLS "${TARGET_NAME}")
  endif()
  find_package(ezEngine ${ezEngine_UNPARSED_ARGUMENTS})

  if(ezEngine_FOUND)
    include_directories("${ezEngine_INCLUDE_DIR}")
    target_link_libraries("${TARGET_NAME}" ${ezEngine_LIBRARIES})
  endif()
endfunction()

function(cf_add_packages TARGET_NAME)
  cf_indent_log_prefix("(packages)")
  cmake_parse_arguments(PKG "cfParser" "" "Catch;SFML;ezEngine" ${ARGN})

  if(PKG_UNPARSED_ARGUMENTS)
    cf_warning_unparsed_args("unparsed arguments: ${PKG_UNPARSED_ARGUMENTS}")
  endif()

  if(PKG_SFML)
    cf_log(1 "adding SFML")
    cf_log(2 "args: ${PKG_SFML}")
    cf_add_sfml("${TARGET_NAME}" "${PKG_SFML}")
  endif()

  if(PKG_ezEngine)
    cf_log(1 "adding ezEngine")
    cf_log(2 "args: ${PKG_ezEngine}")
    cf_add_ezEngine("${TARGET_NAME}" "${PKG_ezEngine}")
  endif()

  if(PKG_cfParser)
    target_link_libraries("${TARGET_NAME}" cfParser)
    foreach(CFG DEBUG RELEASE MINSIZEREL RELWITHDEBINFO)
      get_target_property(cfParser_LIBRARY_OUTPUT_DIR cfParser LIBRARY_OUTPUT_DIRECTORY_${CFG})
      link_directories("${cfParser_LIBRARY_OUTPUT_DIR}")
    endforeach()
  endif()

  if(PKG_Catch)
    cf_log(1 "adding Catch")
    cf_log(2 "args: ${PKG_Catch}")
    find_package(Catch ${PKG_Catch})
    if(Catch_FOUND)
      include_directories("${Catch_INCLUDE_DIR}")
    endif()
  endif()

endfunction(cf_add_packages)

# chooses a file template based on the given FILE_EXTENSION
function(cf_get_file_template FILE_EXTENSION OUTPUT_VARIABLE)
  if("${FILE_EXTENSION}" STREQUAL ".h" OR
     "${FILE_EXTENSION}" STREQUAL ".hpp")
    set(${OUTPUT_VARIABLE} "${CF_FILE_TEMPLATE_DIR}/empty.h.template" PARENT_SCOPE)
  elseif("${FILE_EXTENSION}" STREQUAL ".cpp")
    set(${OUTPUT_VARIABLE} "${CF_FILE_TEMPLATE_DIR}/empty.cpp.template" PARENT_SCOPE)
  elseif("${FILE_EXTENSION}" STREQUAL ".inl")
    set(${OUTPUT_VARIABLE} "${CF_FILE_TEMPLATE_DIR}/empty.inl.template" PARENT_SCOPE)
  endif()
endfunction(cf_get_file_template)

function(cf_create_missing_files)
  cf_indent_log_prefix("(creating missing files)")
  foreach(SRC_FILE ${ARGN})
    set(SRC_FILE "${CMAKE_CURRENT_LIST_DIR}/${SRC_FILE}")
    if(NOT EXISTS "${SRC_FILE}")
      get_filename_component(SRC_FILE_EXT "${SRC_FILE}" EXT)
      cf_get_file_template("${SRC_FILE_EXT}" SRC_TEMPLATE)
      cf_log(3 "using template: ${SRC_TEMPLATE}")
      file(READ "${SRC_TEMPLATE}" SRC_TEMPLATE)
      file(WRITE "${SRC_FILE}" "${SRC_TEMPLATE}")
      cf_log(1 "generated: ${SRC_FILE}")
    endif()
  endforeach()
endfunction(cf_create_missing_files)

# project
########################################################################

# signature:
# cf_project(TheProjectName                        # the name of the project.
#            EXECUTABLE|(LIBRARY SHARED|STATIC)    # marks this project as either an executable or a library.
#            [PCH ThePchFileName]                  # the name of the precompiled-header file;
#                                                  # if given, the project will be set up to use a precompiled header.
#            FILES file0 file1 ... fileN           # all files to include as sources.
#            [PACKAGES (SFML ...)|(ezEngine ...)] # the names and components of the packages this project depends on.
function(cf_project        PROJECT_NAME)
  set(bool_options         EXECUTABLE)
  set(single_value_options LIBRARY
                           PCH)
  set(multi_value_options  FILES
                           PACKAGES)
  cf_indent_log_prefix("{${PROJECT_NAME}}")
  cf_log(2 "parsing arguments")
  cmake_parse_arguments(PROJECT "${bool_options}" "${single_value_options}" "${multi_value_options}" ${ARGN})

  # error checking
  if(LIB_UNPARSED_ARGUMENTS)
    cf_warning_unparsed_args("unparsed args: ${LIB_UNPARSED_ARGUMENTS}")
  endif()

  if(PROJECT_EXECUTABLE AND PROJECT_LIBRARY)
    cf_error("you must either specify 'EXECUTABLE' or 'LIBRARY <value>' for a cf_project, not both.")
  elseif(NOT PROJECT_EXECUTABLE AND NOT PROJECT_LIBRARY)
    cf_error("either the 'EXECUTABLE' or the 'LIBRARY <value>' must be given to a cf_project.")
  endif()

  if(NOT PROJECT_FILES)
    cf_error("No files specified for project: ${PROJECT_NAME}")
  endif()

  cf_create_missing_files(${PROJECT_FILES})

  # actually start using the given data
  if(PROJECT_LIBRARY) # this project is a library
    cf_log(1 "project is a library (${PROJECT_LIBRARY})")
    add_library(${PROJECT_NAME} ${PROJECT_LIBRARY} ${PROJECT_FILES})
  elseif(PROJECT_EXECUTABLE)
    cf_log(1 "project is an executable")
    add_executable(${PROJECT_NAME} ${PROJECT_FILES})
  endif()

  if(PROJECT_PCH)
    if(MSVC)
      cf_msvc_add_pch_flags("${PROJECT_PCH}" ${PROJECT_FILES} PREFIX "${PROJECT_NAME}")
    endif()
  endif(PROJECT_PCH)

  cf_group_sources_by_file_system(${PROJECT_FILES})

  cf_add_packages("${PROJECT_NAME}" ${PROJECT_PACKAGES})

  # add compiler flags
  if (CF_COMPILER_SETTINGS_ALL)
    cf_log(2 "setting compiler flags: ${CF_COMPILER_SETTINGS_ALL}")
    set_target_properties (${PROJECT_NAME} PROPERTIES COMPILE_FLAGS ${CF_COMPILER_SETTINGS_ALL})
  endif ()

  # add linker flags
  if (CF_LINKER_SETTINGS_ALL)
    cf_log(2 "setting linker flags (all): ${CF_LINKER_SETTINGS_ALL}")
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_DEBUG          ${CF_LINKER_SETTINGS_ALL})
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_RELWITHDEBINFO ${CF_LINKER_SETTINGS_ALL})
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_RELEASE        ${CF_LINKER_SETTINGS_ALL})
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_MINSIZEREL     ${CF_LINKER_SETTINGS_ALL})
  endif ()
  if (CF_LINKER_SETTINGS_DEBUG)
    cf_log(2 "setting linker flags (debug): ${CF_LINKER_SETTINGS_DEBUG}")
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_DEBUG          ${CF_LINKER_SETTINGS_DEBUG})
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_RELWITHDEBINFO ${CF_LINKER_SETTINGS_DEBUG})
  endif ()
  if (CF_LINKER_SETTINGS_RELEASE)
    cf_log(2 "setting linker flags (release): ${CF_LINKER_SETTINGS_RELEASE}")
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_RELEASE    ${CF_LINKER_SETTINGS_RELEASE})
    set_target_properties (${PROJECT_NAME} PROPERTIES LINK_FLAGS_MINSIZEREL ${CF_LINKER_SETTINGS_RELEASE})
  endif ()
endfunction(cf_project)
