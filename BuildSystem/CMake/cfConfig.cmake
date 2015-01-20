#cmake

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(CF_USE_PCH ON CACHE BOOL
    "Whether to use precompiled headers (if available) or not.")
set(CF_VERBOSITY 0 CACHE STRING
    "Higher values produce more verbose output.")
set(CF_OUTPUT_DIR "${CMAKE_SOURCE_DIR}/Output" CACHE PATH
    "The directory in which to create the bin and lib folders in.")
set(CF_LOG_PREFIX "[cf]" CACHE STRING
    "String used to prefix all log messages. Useful to quickly identify out log messages.")
set(CF_DISABLED_WARNINGS "" CACHE STRING
    "List of disabled warnings")
set(CF_FILE_TEMPLATE_DIR "${CMAKE_MODULE_PATH}/Templates" CACHE STRING
    "Directory containing all file templates used to generate new files listed in a CMakeLists.txt that does not yet exist on the filesystem.")
set(CF_SHOW_VERBOSITY_IN_LOG OFF CACHE BOOL
    "Whether to show verbosity of a log message or not.")
set(CF_STRICT_WARNINGS OFF CACHE BOOL
    "Whether to use the highest warning level.")

set(CF_COMPILER_SETTINGS_ALL     "" CACHE STRING "Compiler settings used in all builds")
set(CF_COMPILER_SETTINGS_RELEASE "" CACHE STRING "Compiler settings used in release builds only")
set(CF_COMPILER_SETTINGS_DEBUG   "" CACHE STRING "Compiler settings used in debug builds only")
set(CF_LINKER_SETTINGS_ALL       "" CACHE STRING "Linker settings used in all builds")
set(CF_LINKER_SETTINGS_RELEASE   "" CACHE STRING "Linker settings used in release builds only")
set(CF_LINKER_SETTINGS_DEBUG     "" CACHE STRING "Linker settings used in debug builds only")

mark_as_advanced(CF_VERBOSITY
                 CF_LOG_PREFIX
                 CF_DISABLED_WARNINGS
                 CF_FILE_TEMPLATE_DIR
                 CF_SHOW_VERBOSITY_IN_LOG

                 CF_COMPILER_SETTINGS_ALL
                 CF_COMPILER_SETTINGS_RELEASE
                 CF_COMPILER_SETTINGS_DEBUG
                 CF_LINKER_SETTINGS_ALL
                 CF_LINKER_SETTINGS_RELEASE
                 CF_LINKER_SETTINGS_DEBUG)

set(CF_OUTPUT_DIR_BIN "${CF_OUTPUT_DIR}/Bin")
set(CF_OUTPUT_DIR_LIB "${CF_OUTPUT_DIR}/Lib")

# the following is a modified and stripped version of
# CMAKE_GeneralConfig.txt taken from the ezEngine project.

## other configuration
#######################################################################

# setthe default build type
if(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Debug CACHE STRING
      "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel."
      FORCE)
endif()

#########################################################################################
## Detects the current platform

set(CF_PLATFORM_PREFIX "")

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  # Windows
  cf_log(1 "Platform is Windows (CF_BUILDSYSTEM_PLATFORM_WINDOWS)")
  set(CF_BUILDSYSTEM_PLATFORM_WINDOWS ON)
  set(CF_PLATFORM_PREFIX "Win")

elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND CURRENT_OSX_VERSION)
  # OS X
  cf_log(1 "Platform is OS X (CF_BUILDSYSTEM_PLATFORM_OSX, CF_BUILDSYSTEM_PLATFORM_POSIX)")
  set(CF_BUILDSYSTEM_PLATFORM_OSX ON)
  set(CF_BUILDSYSTEM_PLATFORM_POSIX ON)
  set(CF_PLATFORM_PREFIX "Osx")

elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  # Linux
  cf_log(1 "Platform is Linux (CF_BUILDSYSTEM_PLATFORM_LINUX, CF_BUILDSYSTEM_PLATFORM_POSIX)")
  set(CF_BUILDSYSTEM_PLATFORM_LINUX ON)
  set(CF_BUILDSYSTEM_PLATFORM_POSIX ON)
  set(CF_PLATFORM_PREFIX "Linux")

else()
  CF_fatal("Platform '${CMAKE_SYSTEM_NAME}' is not supported! Please extend krepelConfig.cmake.")
endif()


#########################################################################################
## Detects the current build-system / generator

set(CF_BUILDSYSTEM_PREFIX "")

if(CF_BUILDSYSTEM_PLATFORM_WINDOWS)
  # Supported windows generators
  if(MSVC)
    # Visual Studio (All VS generators define MSVC)
    cf_log(1 "Buildsystem is MSVC (CF_BUILDSYSTEM_MSVC)")
    set(CF_BUILDSYSTEM_MSVC ON)
    set(CF_BUILDSYSTEM_PREFIX "Vs")
    set(CF_BUILDSYSTEM_CONFIGURATION $<CONFIGURATION>)
  else()
    CF_fatal("Generator '${CMAKE_GENERATOR}' is not supported on Windows! Please extend krepelConfig.cmake.")
  endif()

elseif(CF_BUILDSYSTEM_PLATFORM_OSX)
  # Supported OSX generators
  if(CMAKE_GENERATOR STREQUAL "Xcode")
    # XCODE
    cf_log(1 "Buildsystem is Xcode (CF_BUILDSYSTEM_XCODE)")
    set(CF_BUILDSYSTEM_XCODE ON)
    set(CF_BUILDSYSTEM_PREFIX "Xcode")
    set(CF_BUILDSYSTEM_CONFIGURATION $<CONFIGURATION>)
  elseif(CMAKE_GENERATOR STREQUAL "Unix Makefiles")
    # Unix Makefiles (for QtCreator etc.)
    cf_log(1 "Buildsystem is Make (CF_BUILDSYSTEM_MAKE)")
    set(CF_BUILDSYSTEM_MAKE ON)
    set(CF_BUILDSYSTEM_PREFIX "Make")
    set(CF_BUILDSYSTEM_CONFIGURATION ${CMAKE_BUILD_TYPE})
  else()
    CF_fatal("Generator '${CMAKE_GENERATOR}' is not supported on OS X! Please extend krepelConfig.cmake.")
  endif()

elseif(CF_BUILDSYSTEM_PLATFORM_LINUX)
  if(CMAKE_GENERATOR STREQUAL "Unix Makefiles")
    # Unix Makefiles (for QtCreator etc.)
    cf_log(1 "Buildsystem is Make (CF_BUILDSYSTEM_MAKE)")
    set(CF_BUILDSYSTEM_MAKE ON)
    set(CF_BUILDSYSTEM_PREFIX "Make")
    set(CF_BUILDSYSTEM_CONFIGURATION ${CMAKE_BUILD_TYPE})
  else()
    CF_fatal("Generator '${CMAKE_GENERATOR}' is not supported on Linux! Please extend krepelConfig.cmake.")
  endif()

else()
  CF_fatal("Platform '${CMAKE_SYSTEM_NAME}' has not setup the supported generators. Please extend krepelConfig.cmake.")
endif()

#########################################################################################
## Detects the current compiler

set(CF_COMPILER_POSTFIX "")

if(CF_BUILDSYSTEM_MSVC)
  # Visual Studio Compiler
  cf_log(1 "Compiler is MSVC (CF_BUILDSYSTEM_COMPILER_MSVC)")
  set(CF_BUILDSYSTEM_COMPILER_MSVC ON)

  if(MSVC12)
    cf_log(1 "Compiler is Visual Studio 120 (2013) (CF_BUILDSYSTEM_COMPILER_MSVC_120)")
    set(CF_BUILDSYSTEM_COMPILER_MSVC_120 ON)
    set(CF_COMPILER_POSTFIX "120")
  elseif(MSVC11)
    cf_log(1 "Compiler is Visual Studio 110 (2012) (CF_BUILDSYSTEM_COMPILER_MSVC_110)")
    set(CF_BUILDSYSTEM_COMPILER_MSVC_110 ON)
    set(CF_COMPILER_POSTFIX "110")
  elseif(MSVC10)
    cf_log(1 "Compiler is Visual Studio 100 (2010) (CF_BUILDSYSTEM_COMPILER_MSVC_100)")
    set(CF_BUILDSYSTEM_COMPILER_MSVC_100 ON)
    set(CF_COMPILER_POSTFIX "100")
  else()
    CF_fatal("Compiler for generator '${CMAKE_GENERATOR}' is not supported on MSVC! Please extend krepelConfig.cmake.")
  endif()

elseif(CF_BUILDSYSTEM_PLATFORM_OSX)
  # Currently all are clang by default.
  # We should probably make this more idiot-proof in case someone actually changes the compiler to gcc.
  cf_log(1 "Compiler is clang (CF_BUILDSYSTEM_COMPILER_CLANG)")
  set(CF_BUILDSYSTEM_COMPILER_CLANG ON)
  set(CF_COMPILER_POSTFIX "Clang")

elseif(CF_BUILDSYSTEM_PLATFORM_LINUX)
  # Currently all are gcc by default. See OSX comment.
  cf_log(1 "Compiler is gcc (CF_BUILDSYSTEM_COMPILER_GCC)")
  set(CF_BUILDSYSTEM_COMPILER_GCC ON)
  set(CF_COMPILER_POSTFIX "Gcc")

else()
  CF_fatal("Compiler for generator '${CMAKE_GENERATOR}' is not supported on '${CMAKE_SYSTEM_NAME}'. Please extend krepelConfig.cmake.")
endif()


#########################################################################################
## Detects the current architecture

set(CF_ARCHITECTURE_POSTFIX "")

if(CF_BUILDSYSTEM_PLATFORM_WINDOWS AND CF_BUILDSYSTEM_COMPILER_MSVC)
  # Detect 64-bit builds for MSVC.
  if(CMAKE_CL_64)
    cf_log(1 "Platform is 64-Bit (CF_BUILDSYSTEM_PLATFORM_64BIT)")
    set(CF_BUILDSYSTEM_PLATFORM_64BIT ON)
    set(CF_ARCHITECTURE_POSTFIX "64")
  else()
    cf_log(1 "Platform is 32-Bit (CF_BUILDSYSTEM_PLATFORM_32BIT)")
    set(CF_BUILDSYSTEM_PLATFORM_32BIT ON)
    set(CF_ARCHITECTURE_POSTFIX "32")
  endif()

elseif(CF_BUILDSYSTEM_PLATFORM_OSX AND CF_BUILDSYSTEM_COMPILER_CLANG)
  # OS X always has 32/64 bit support in the project files and the user switches on demand.
  # However, we do not support 32 bit with our current build configuration so we throw an error on 32-bit systems.
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    cf_log(1 "Platform is 64-Bit (CF_BUILDSYSTEM_PLATFORM_64BIT)")
    set(CF_BUILDSYSTEM_PLATFORM_64BIT ON)
    set(CF_ARCHITECTURE_POSTFIX "64")
  else()
    CF_fatal("32-Bit is not supported on OS X!")
  endif()

elseif(CF_BUILDSYSTEM_PLATFORM_LINUX AND CF_BUILDSYSTEM_COMPILER_GCC)
  # Detect 64-bit builds for Linux, no other way than checking CMAKE_SIZEOF_VOID_P.
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    cf_log(1 "Platform is 64-Bit (CF_BUILDSYSTEM_PLATFORM_64BIT)")
    set(CF_BUILDSYSTEM_PLATFORM_64BIT ON)
    set(CF_ARCHITECTURE_POSTFIX "64")
  else()
    cf_log(1 "Platform is 32-Bit (CF_BUILDSYSTEM_PLATFORM_32BIT)")
    set(CF_BUILDSYSTEM_PLATFORM_32BIT ON)
    set(CF_ARCHITECTURE_POSTFIX "32")
  endif()

else()
  CF_fatal("Architecture could not be determined. Please extend krepelConfig.cmake.")
endif()

## tell cmake where to build our stuff to
#######################################################################

set(CF_OUTPUT_LIB_DEBUG          "${CF_OUTPUT_DIR_LIB}/${CF_PLATFORM_PREFIX}${CF_BUILDSYSTEM_PREFIX}${CF_COMPILER_POSTFIX}Debug${CF_ARCHITECTURE_POSTFIX}")
set(CF_OUTPUT_LIB_RELEASE        "${CF_OUTPUT_DIR_LIB}/${CF_PLATFORM_PREFIX}${CF_BUILDSYSTEM_PREFIX}${CF_COMPILER_POSTFIX}Release${CF_ARCHITECTURE_POSTFIX}")
set(CF_OUTPUT_LIB_MINSIZE        "${CF_OUTPUT_DIR_LIB}/${CF_PLATFORM_PREFIX}${CF_BUILDSYSTEM_PREFIX}${CF_COMPILER_POSTFIX}MinSize${CF_ARCHITECTURE_POSTFIX}")
set(CF_OUTPUT_LIB_RELWITHDEBINFO "${CF_OUTPUT_DIR_LIB}/${CF_PLATFORM_PREFIX}${CF_BUILDSYSTEM_PREFIX}${CF_COMPILER_POSTFIX}RelWithDebInfo${CF_ARCHITECTURE_POSTFIX}")

set(CF_OUTPUT_BIN_DEBUG          "${CF_OUTPUT_DIR_BIN}/${CF_PLATFORM_PREFIX}${CF_BUILDSYSTEM_PREFIX}${CF_COMPILER_POSTFIX}Debug${CF_ARCHITECTURE_POSTFIX}")
set(CF_OUTPUT_BIN_RELEASE        "${CF_OUTPUT_DIR_BIN}/${CF_PLATFORM_PREFIX}${CF_BUILDSYSTEM_PREFIX}${CF_COMPILER_POSTFIX}Release${CF_ARCHITECTURE_POSTFIX}")
set(CF_OUTPUT_BIN_MINSIZE        "${CF_OUTPUT_DIR_BIN}/${CF_PLATFORM_PREFIX}${CF_BUILDSYSTEM_PREFIX}${CF_COMPILER_POSTFIX}MinSize${CF_ARCHITECTURE_POSTFIX}")
set(CF_OUTPUT_BIN_RELWITHDEBINFO "${CF_OUTPUT_DIR_BIN}/${CF_PLATFORM_PREFIX}${CF_BUILDSYSTEM_PREFIX}${CF_COMPILER_POSTFIX}RelWithDebInfo${CF_ARCHITECTURE_POSTFIX}")

cf_log(1 "source dir:     ${CMAKE_SOURCE_DIR}")
cf_log(1 "bin output dir: ${CF_OUTPUT_DIR_BIN}")
cf_log(1 "lib output dir: ${CF_OUTPUT_DIR_LIB}")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY                 "${CF_OUTPUT_BIN_DEBUG}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG           "${CF_OUTPUT_BIN_DEBUG}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE         "${CF_OUTPUT_BIN_RELEASE}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL      "${CF_OUTPUT_BIN_MINSIZE}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO  "${CF_OUTPUT_BIN_RELWITHDEBINFO}")

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY                 "${CF_OUTPUT_LIB_DEBUG}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG           "${CF_OUTPUT_LIB_DEBUG}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE         "${CF_OUTPUT_LIB_RELEASE}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL      "${CF_OUTPUT_LIB_MINSIZE}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO  "${CF_OUTPUT_LIB_RELWITHDEBINFO}")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY                 "${CF_OUTPUT_LIB_DEBUG}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG           "${CF_OUTPUT_LIB_DEBUG}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE         "${CF_OUTPUT_LIB_RELEASE}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL      "${CF_OUTPUT_LIB_MINSIZE}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO  "${CF_OUTPUT_LIB_RELWITHDEBINFO}")

## compiler specific settings
#######################################################################

if(CF_BUILDSYSTEM_COMPILER_MSVC)
  # Enable minimal rebuild
  set(CF_COMPILER_SETTINGS_DEBUG "${CF_COMPILER_SETTINGS_DEBUG} /Gm")
  # enable multi-threaded compilation
  set(CF_COMPILER_SETTINGS_ALL "${CF_COMPILER_SETTINGS_ALL} /MP")
  # disable RTTI
  set(CF_COMPILER_SETTINGS_ALL "${CF_COMPILER_SETTINGS_ALL} /GR-")
  # use fast floating point model
  set(CF_COMPILER_SETTINGS_ALL "${CF_COMPILER_SETTINGS_ALL} /fp:fast")
  # enable floating point exceptions
  #set(CF_COMPILER_SETTINGS_ALL "${CF_COMPILER_SETTINGS_ALL} /fp:except")

  # enable strict warnings
  if(CF_STRICT_WARNINGS)
    set(CF_COMPILER_SETTINGS_ALL "${CF_COMPILER_SETTINGS_ALL} /W4")
  endif()
  # treat warnings as errors
  set(CF_COMPILER_SETTINGS_ALL "${CF_COMPILER_SETTINGS_ALL} /WX")

  if(BUILDSYSTEM_PLATFORM_32BIT)
    # enable SSE2 (incompatible with /fp:except)
    set(CF_COMPILER_SETTINGS_ALL "${CF_COMPILER_SETTINGS_ALL} /arch:SSE2")

    if(MSVC10)
      # enable static code analysis, only works on 32 Bit builds
      # (may cause compile errors when combined with Qt, disabled for the time being)
      #set(CF_COMPILER_SETTINGS_ALL "${CF_COMPILER_SETTINGS_ALL} /analyze")
      #message (STATUS "Enabling static code analysis.")
    endif()
  endif()

  if(MSVC11 OR MSVC12)
    #set(CF_COMPILER_SETTINGS_ALL "${CF_COMPILER_SETTINGS_ALL} /analyze")
    set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /d2Zi+")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /d2Zi+")
  endif()

  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /Ox /Ob2 /Oi")
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Ox /Ob2 /Oi")

  set(CF_LINKER_SETTINGS_RELEASE "${CF_LINKER_SETTINGS_RELEASE} /INCREMENTAL:NO")
  # Remove unreferenced data (does not work together with incremental build)
  set(CF_LINKER_SETTINGS_RELEASE "${CF_LINKER_SETTINGS_RELEASE} /OPT:REF")
  # Don't know what it does, but Clemens wants it :-) (does not work together with incremental build)
  set(CF_LINKER_SETTINGS_RELEASE "${CF_LINKER_SETTINGS_RELEASE} /OPT:ICF")

elseif(CF_BUILDSYSTEM_COMPILER_CLANG)
  # Enable c++11 features
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -stdlib=libc++")
elseif(CF_BUILDSYSTEM_COMPILER_GCC)
  # dynamic linking will fail without fPIC (plugins)
  # Wno-enum-compare removes all annoying enum cast warnings
  # std=c++11 is - well needed for c++11.
  # gdwarf-3 will use the old debug info which is compatible with older gdb versions.
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -Wno-enum-compare -std=c++11 -mssse3 -mfpmath=sse -gdwarf-3")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -gdwarf-3")

else()
  message (FATAL_ERROR "Not settings are defined for the selected compiler. Please extend krepelConfig.cmake.")
endif()
