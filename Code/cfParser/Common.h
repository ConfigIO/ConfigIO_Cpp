#pragma once

#ifdef WIN32
#   ifdef cfParser_EXPORTS
#      define CF_PARSER_API __declspec(dllexport)
#   else
#      define CF_PARSER_API __declspec(dllimport)
#   endif
#else
#   define CF_PARSER_API
#endif // WIN32

namespace cf
{
   CF_PARSER_API const char* getVersionString();
}
