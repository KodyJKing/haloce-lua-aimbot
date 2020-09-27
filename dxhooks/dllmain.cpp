#include "dllmain.h"

using namespace std;

HMODULE myHModule;
HookRecord setTextureHookRecord;
unordered_map < uint64_t, IDirect3DBaseTexture9*> textureOverrides;
unordered_map < IDirect3DBaseTexture9*, uint64_t> textureHashes;
mutex textureOverrideMutex;

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

const string outdir = filesystem::current_path().string() + string("\\TEXTURE_DUMP\\");
const string indir = filesystem::current_path().string() + string("\\TEXTURE_SWAP\\");
DWORD __stdcall myThread(LPVOID lpParameter) {
    AllocConsole();
    FILE* pFile;
    auto err = freopen_s(&pFile, "CONOUT$", "w", stdout);

    cout << "Hello from module:  " << to_string((int)myHModule) << endl;
    cout << "Output dir: " << outdir << endl;

    loadSwaps();
    hookSetTexture();

    if (!err) {
        while (TRUE) {
            Sleep(50);
            if (GetAsyncKeyState(VK_F9))
                break;
            if (GetAsyncKeyState(VK_F5))
                loadSwaps();
        }
    }

    removeHook(setTextureHookRecord);
    if (pFile) fclose(pFile);
    FreeConsole();
    FreeLibraryAndExitThread(myHModule, 0);
}

void loadSwaps() {
    textureOverrideMutex.lock();
    cout << "(re)loading texture overrides" << endl;
    textureOverrides.clear();
    for (auto entry : filesystem::directory_iterator(indir)) {
        IDirect3DTexture9* pTexture;
        D3DXCreateTextureFromFile(
            getPDevice(),
            entry.path().c_str(),
            &pTexture
        );

        // Get file hash from filename.
        string filename = entry.path().filename().string();
        filename = filename.substr(0, filename.length() - 4);
        uint64_t hash = stoull(filename);

        textureOverrides[hash] = pTexture;
    }
    textureOverrideMutex.unlock();
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

int callCounter = 0;
HRESULT __stdcall setTextureHook(
    IDirect3DDevice9* pThisDevice,
    DWORD stage,
    IDirect3DBaseTexture9* pTexture
) {
    if (textureHashes.count(pTexture) > 0) {
        uint64_t hash = textureHashes[pTexture];
        textureOverrideMutex.lock();
        if (textureOverrides.count(hash) > 0)
            pTexture = textureOverrides[hash];
        textureOverrideMutex.unlock();
    } else {
        registerTexture(pTexture);
    }
    return ((SetTextureFunc)setTextureHookRecord.oldMethod)(pThisDevice, stage, pTexture);
}

void registerTexture(IDirect3DBaseTexture9* pTexture) {
    if (pTexture == nullptr)
        return;

    uint64_t hash;
    try {
        // cout << "Hashing texture " << to_string((int)pTexture) << endl;
        hash = computeTextureHash(pTexture);
        textureHashes[pTexture] = hash;
        // string saveLocation = outdir + to_string(hash) + ".png";
        // cout << "Saving texture to " << saveLocation << endl;
        // D3DXSaveTextureToFileA(
        //     saveLocation.c_str(),
        //     D3DXIFF_PNG,
        //     pTexture,
        //     NULL
        // );
    } catch (int e) {
        cout << "Error hashing and saving texture: " << to_string(e);
    }

    int textureCount = textureHashes.size();
    cout << "texture count: " << to_string(textureCount) << endl;
}

uint64_t computeTextureHash(IDirect3DBaseTexture9* pTexture) {
    ID3DXBuffer* pBuffer;
    auto err = D3DXSaveTextureToFileInMemory(
        &pBuffer,
        D3DXIFF_PNG,
        pTexture,
        NULL
    );
    if (err) throw err;
    if (pBuffer == nullptr) throw 42;
    DWORD size = pBuffer->GetBufferSize();
    LPVOID buffer = pBuffer->GetBufferPointer();
    uint64_t result = hashBuffer((BYTE*)buffer, size);
    pBuffer->Release();
    return result;
}

uint64_t hashBuffer(BYTE* buf, DWORD length) {
    uint64_t result = 5381;
    for (DWORD i = 0; i < length; i++)
        result = ((result << 5) + result) + buf[i];
    return result;
}

