#include "dllmain.h"

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

    if (!err) {
        while (TRUE) {
            Sleep(50);
            if (GetAsyncKeyState(VK_F9))
                break;
        }
    }

    removeHook(setTextureHookRecord);
    if (pFile) fclose(pFile);
    FreeConsole();
    FreeLibraryAndExitThread(myHModule, 0);
}

IDirect3DDevice9* getPDevice() {
    // Found device location by backtracing a device method call.
    // Found device method using virtual table from dummy device.
    // https://gist.github.com/KodyJKing/d7b374b29998dfdd7d631430164f3e50
    IDirect3DDevice9** ppDevice = (IDirect3DDevice9**)0x0071D174;
    IDirect3DDevice9* pDevice = *ppDevice;
    return pDevice;
}

void** getDeviceVirtualTable() {
    IDirect3DDevice9* pDevice = getPDevice();
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

// IDirect3DBaseTexture9* firstPTexture = nullptr;

set<IDirect3DBaseTexture9*> textures;
int callCounter = 0;
HRESULT __stdcall setTextureHook(
    IDirect3DDevice9* pThisDevice,
    DWORD stage,
    IDirect3DBaseTexture9* pTexture
) {
    bool isNew = textures.count(pTexture) == 0;
    if (isNew) {
        textures.insert(pTexture);
        string saveLocation = "C:/Users/Kody/Desktop/textureDump/" + to_string((int)pTexture) + ".png";
        D3DXSaveTextureToFileA(
            saveLocation.c_str(),
            D3DXIFF_PNG,
            pTexture,
            NULL
        );
    }
    int textureCount = textures.size();
    if (callCounter++ % 100 == 0) cout << "texture count: " << to_string(textureCount) << endl;

    return ((SetTextureFunc)setTextureHookRecord.oldMethod)(pThisDevice, stage, pTexture);
}