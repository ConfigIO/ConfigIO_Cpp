#include "cfParserTests/pch.h"
#include <catch.hpp>

CATCH_TEST_CASE("Common functionality", "[common]")
{
   CATCH_SECTION("get the version string")
   {
      CATCH_REQUIRE(cf::getVersionString() == std::string("0.1.0"));
   }
}
