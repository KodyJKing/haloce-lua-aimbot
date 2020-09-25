// dllmain.cpp : Defines the entry point for the DLL application.
#include <Windows.h>
#include <iostream>
#include <string>
#include "dllmain.h"

HMODULE myHModule;

DWORD __stdcall myThread(LPVOID lpParameter) {
    AllocConsole();
    FILE* pFile;
    auto err = freopen_s(&pFile, "CONOUT$", "w", stdout);

    std::cout << "Hello from module:  " << std::to_string((int)myHModule) << std::endl;

    int updateMeAndRecompileToTestUnloading = 42;
    if (!err) {
        while (TRUE) {
            Sleep(100);
            if (GetAsyncKeyState(VK_F9))
                break;
        }
    }

    if (pFile) fclose(pFile);
    FreeConsole();
    FreeLibraryAndExitThread(myHModule, 0);
}

BOOL APIENTRY DllMain(HMODULE hModule,
    DWORD  ul_reason_for_call,
    LPVOID lpReserved
)
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        myHModule = hModule;
        CreateThread(0, 0, myThread, 0, 0, 0);
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}

