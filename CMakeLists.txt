#cmake

# our dependency 'cotire' needs at least this version
cmake_minimum_required(VERSION 2.8.6)

# name of the entire project
project("ConfigIO")

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/BuildSystem/CMake")
include(cfUtilities)

# the sub-directory 'Code' contains all source code.
add_subdirectory("Code") # execute CMake code in Code/CMakeLists.txt
