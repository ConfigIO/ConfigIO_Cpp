
cf_project(
   cfParserTests
   EXECUTABLE
   PCH PCH.h
   FILES
      PCH.h
      PCH.cpp
      Main.cpp
      # Add source files below
      TestCommon.cpp
   PACKAGES
      cfParser
      Catch REQUIRED
)
