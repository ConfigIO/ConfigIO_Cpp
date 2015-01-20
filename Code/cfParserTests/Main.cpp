#include "cfParserTests/PCH.h"

#define CATCH_CONFIG_RUNNER
#include <catch.hpp>

int main(int argc, char* const argv[])
{
   Catch::Session session;
   auto result = session.run(argc, argv);
   return result;
}
