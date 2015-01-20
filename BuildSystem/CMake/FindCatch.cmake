#cmake

########################################################################
# Tries to find the Catch testing framework header.
# Input:
#   Catch_HEADER_FILE:  The path to the header file catch.hpp.
# Output:
#   Catch_FOUND:        TRUE if all required components were PACKAGES_FOUND
#   Catch_INCLUDE_DIR:  The include directory of the Catch sources. Use it like this: include_directories("${Catch_INCLUDE_DIR}")
########################################################################

set(Catch_HEADER_FILE "" CACHE FILEPATH
    "The path to the header file catch.hpp.")
find_file(Catch_HEADER_FILE
          NAMES "catch.hpp"
          PATHS "single_include" "include")

if(Catch_HEADER_FILE)
  set(Catch_FOUND TRUE)
endif()

if(NOT Catch_FOUND)
  set(Catch_FIND_MESSAGE "Unable to locate Catch. Please specify Catch_HEADER_FILE.")
  if(Catch_FIND_REQUIRED)
    message(SEND_ERROR "${Catch_FIND_MESSAGE}")
  else()
    message(STATUS "${Catch_FIND_MESSAGE}")
  endif()
  return()
endif()

get_filename_component(Catch_INCLUDE_DIR "${Catch_HEADER_FILE}" DIRECTORY)

message(STATUS "Found Catch in: ${Catch_INCLUDE_DIR}")
