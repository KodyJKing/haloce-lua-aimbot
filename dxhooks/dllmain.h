#include <Windows.h>
#include <iostream>
#include <filesystem>
#include <string>
#include <unordered_map>
#include <mutex>
#include <set>
#include <d3d9.h>
#include <d3dx9.h>

#pragma comment(lib, "d3d9.lib")
#pragma comment(lib, "d3dx9.lib")

#pragma once

typedef HRESULT(__stdcall* SetTextureFunc)(IDirect3DDevice9* pThisDevice, DWORD stage, IDirect3DBaseTexture9* pTexture);

typedef HRESULT(__stdcall* CreateTextureFunc)(
    UINT              Width,
    UINT              Height,
    UINT              Levels,
    DWORD             Usage,
    D3DFORMAT         Format,
    D3DPOOL           Pool,
    IDirect3DTexture9** ppTexture,
    HANDLE* pSharedHandle
    );

DWORD __stdcall myThread(LPVOID lpParameter);

void loadSwaps();

void hookSetTexture();
HRESULT __stdcall setTextureHook(IDirect3DDevice9* pThisDevice, DWORD stage, IDirect3DBaseTexture9* pTexture);
void registerTexture(IDirect3DBaseTexture9* pTexture);
uint64_t computeTextureHash(IDirect3DBaseTexture9* pTexture);
uint64_t hashBuffer(BYTE* buf, DWORD length);

IDirect3DDevice9* getPDevice();
void** getDeviceVirtualTable();

struct HookRecord {
    const char* description;
    void** vtable;
    int methodIndex;
    void* oldMethod;
    void* newMethod;
};
HookRecord addHook(const char* description, void** vtable, int methodIndex, void* newMethod);
void removeHook(HookRecord record);