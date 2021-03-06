#include "./commandlineutils.h"

#include <string>
#include <iostream>

#ifdef PLATFORM_WINDOWS
# include <windows.h>
# include <fcntl.h>
#endif

using namespace std;

namespace ApplicationUtilities {

/*!
 * \brief Prompts for confirmation displaying the specified \a message.
 */
bool confirmPrompt(const char *message, Response defaultResponse)
{
    cout << message;
    cout << ' ' << '[';
    cout << (defaultResponse == Response::Yes ? 'Y' : 'y');
    cout << '/' << (defaultResponse == Response::No ? 'N' : 'n');
    cout << ']' << ' ';
    cout.flush();
    for(string line; ;) {
        getline(cin, line);
        if(line == "y" || line == "Y" || (defaultResponse == Response::Yes && line.empty())) {
            return true;
        } else if(line == "n" || line == "N" || (defaultResponse == Response::No && line.empty())) {
            return false;
        } else {
            cout << "Please enter [y] or [n]: ";
            cout.flush();
        }
    }
}

#ifdef PLATFORM_WINDOWS
/*!
 * \brief Starts the console and sets the console output code page to UTF-8 if this is configured.
 * \remarks This method is only available on Windows and used to start a console from a GUI application.
 */
void startConsole()
{
    AttachConsole(ATTACH_PARENT_PROCESS);
    CONSOLE_SCREEN_BUFFER_INFO coninfo;
    GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &coninfo);
    coninfo.dwSize.X = 200;
    coninfo.dwSize.Y = 500;
    SetConsoleScreenBufferSize(GetStdHandle(STD_OUTPUT_HANDLE), coninfo.dwSize);
    // redirect stdout
    auto stdHandle = reinterpret_cast<intptr_t>(GetStdHandle(STD_OUTPUT_HANDLE));
    auto conHandle = _open_osfhandle(stdHandle, _O_TEXT);
    auto fp = _fdopen(conHandle, "w");
    *stdout = *fp;
    setvbuf(stdout, NULL, _IONBF, 0);
    // redirect stdin
    stdHandle = reinterpret_cast<intptr_t>(GetStdHandle(STD_INPUT_HANDLE));
    conHandle = _open_osfhandle(stdHandle, _O_TEXT);
    fp = _fdopen(conHandle, "r");
    *stdin = *fp;
    setvbuf(stdin, NULL, _IONBF, 0);
    // redirect stderr
    stdHandle = reinterpret_cast<intptr_t>(GetStdHandle(STD_ERROR_HANDLE));
    conHandle = _open_osfhandle(stdHandle, _O_TEXT);
    fp = _fdopen(conHandle, "w");
    *stderr = *fp;
    setvbuf(stderr, NULL, _IONBF, 0);
#ifdef CPP_UTILITIES_FORCE_UTF8_CODEPAGE
    // set console to handle UTF-8 IO correctly
    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);
#endif
    // sync
    ios::sync_with_stdio(true);
}

/*!
 * \brief Convert command line arguments to UTF-8.
 * \remarks Only available on Windows (on other platforms we can assume passed arguments are already UTF-8 encoded).
 */
pair<vector<unique_ptr<char[]> >, vector<char *> > convertArgsToUtf8()
{
    pair<vector<unique_ptr<char[]> >, vector<char *> > res;
    int argc;

    LPWSTR *argv_w = CommandLineToArgvW(GetCommandLineW(), &argc);
    if(!argv_w || argc <= 0) {
        return res;
    }

    res.first.reserve(static_cast<size_t>(argc));
    res.second.reserve(static_cast<size_t>(argc));
    for(; argv_w; ++argv_w) {
        int requiredSize = WideCharToMultiByte(CP_UTF8, 0, *argv_w, -1, nullptr, 0, 0, 0);
        if(requiredSize <= 0) {
            break; // just stop on error
        }

        auto argv = make_unique<char[]>(static_cast<size_t>(requiredSize));
        requiredSize = WideCharToMultiByte(CP_UTF8, 0, *argv_w, -1, argv.get(), requiredSize, 0, 0);
        if(requiredSize <= 0) {
            break;
        }

        res.second.emplace_back(argv.get());
        res.first.emplace_back(move(argv));
    }

    LocalFree(argv_w);
    return res;
}
#endif

} // namespace ApplicationUtilities
