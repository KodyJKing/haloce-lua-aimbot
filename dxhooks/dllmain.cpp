// dllmain.cpp : Defines the entry point for the DLL application.
#include "dllmain.h"

#pragma comment(lib, "d3d9.lib")

using namespace std;

HMODULE myHModule;
HookRecord setTextureHookRecord;

BOOL APIENTRY DllMain(HMODULE hModule,
    DWORD  ul_reason_for_call,
    LPVOID lpReserved
) {
    switch (ul_reason_for_call) {
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

DWORD __stdcall myThread(LPVOID lpParameter) {
    AllocConsole();
    FILE* pFile;
    auto err = freopen_s(&pFile, "CONOUT$", "w", stdout);

    cout << "Hello from module:  " << to_string((int)myHModule) << endl;

    hookSetTexture();

    int updateMeAndRecompileToTestUnloading = 42;
    if (!err) {
        while (TRUE) {
            Sleep(100);
            if (GetAsyncKeyState(VK_F9))
                break;
        }
    }

    removeHook(setTextureHookRecord);
    if (pFile) fclose(pFile);
    FreeConsole();
    FreeLibraryAndExitThread(myHModule, 0);
}

void** getDeviceVirtualTable() {
    // Found device location by backtracing a device method call.
    // Found device method using virtual table from dummy device.
    // https://gist.github.com/KodyJKing/d7b374b29998dfdd7d631430164f3e50
    IDirect3DDevice9** ppDevice = (IDirect3DDevice9**)0x0071D174;
    IDirect3DDevice9* pDevice = *ppDevice;
    void** vTable = *(void***)(pDevice);
    return vTable;
}

HookRecord addHook(const char* description, void** vtable, int methodIndex, void* newMethod) {
    cout << "Adding hook: " << description << endl;
    HookRecord record{};
    record.description = description;
    record.vtable = vtable;
    record.methodIndex = methodIndex;
    record.newMethod = newMethod;
    record.oldMethod = vtable[methodIndex];
    vtable[methodIndex] = newMethod;
    return record;
}

void removeHook(HookRecord record) {
    cout << "Removing hook: " << record.description << endl;
    record.vtable[record.methodIndex] = record.oldMethod;
}

void hookSetTexture() {
    void** vTable = getDeviceVirtualTable();
    setTextureHookRecord = addHook("SetTexture", vTable, 65, setTextureHook);
}

int callCounter = 0;
HRESULT __stdcall setTextureHook(
    IDirect3DDevice9* pThisDevice,
    DWORD stage,
    IDirect3DBaseTexture9* pTexture
) {
    if (callCounter++ % 100 == 0) cout << "logging from within hook!" << endl;
    return ((SetTextureFunc)setTextureHookRecord.oldMethod)(pThisDevice, stage, pTexture);
}