#include <Windows.h>
#include <iostream>
#include <string>
#include <set>
#include <d3d9.h>
// #include <d3dx9.h>

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

void hookSetTexture();

HRESULT __stdcall setTextureHook(IDirect3DDevice9* pThisDevice, DWORD stage, IDirect3DBaseTexture9* pTexture);

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