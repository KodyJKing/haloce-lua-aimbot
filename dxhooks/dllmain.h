#include <Windows.h>
#include <iostream>
#include <string>
#include <d3d9.h>

#pragma once

typedef HRESULT(__stdcall* SetTextureFunc)(IDirect3DDevice9* pThisDevice, DWORD stage, IDirect3DBaseTexture9* pTexture);

DWORD __stdcall myThread(LPVOID lpParameter);

void hookSetTexture();

HRESULT __stdcall setTextureHook(IDirect3DDevice9* pThisDevice, DWORD stage, IDirect3DBaseTexture9* pTexture);

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