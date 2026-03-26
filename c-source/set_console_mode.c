#include <windows.h>
#include <stdio.h>

int main()
{
    HANDLE stdout_handle;
    DWORD mode = 0;

    stdout_handle = GetStdHandle(STD_OUTPUT_HANDLE);

    GetConsoleMode(stdout_handle, &mode);
    SetConsoleMode(stdout_handle, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
    return 0;
}
