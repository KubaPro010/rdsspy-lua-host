#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <shlobj.h>
#include "lua/lua.h"
#include "lua/lualib.h"
#include "lua/lauxlib.h"

typedef struct {
    unsigned short Year;
    unsigned char Month;
    unsigned char Day;
    unsigned char Hour;
    unsigned char Minutes;
    unsigned char Second;
    unsigned char Centisecond;
    unsigned short RFU;
    int Blk1;
    int Blk2;
    int Blk3;
    int Blk4;
} TRDSGroup;

typedef struct {
    // fuckass delphi
    unsigned char len;
    char data[255];
} ShortString;

typedef struct {
    ShortString Key;
    ShortString Value;
} TRecord;

typedef struct {
    int Count;
    TRecord Records[255];
} TDB;

static TRDSGroup Group;

static HWND hWnd = NULL;
static HINSTANCE hInst = NULL;

static lua_State* L = NULL;

static HWND hEditControl = NULL;

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg)
    {
        case WM_CLOSE:
            ShowWindow(hwnd, SW_HIDE);  // hide instead of destroy (DLL-safe)
            return 0;

        case WM_DESTROY:
            hWnd = NULL;
            return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

void CreatePluginWindow(HWND hOwner)
{
    WNDCLASS wc = {0};
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInst;
    wc.lpszClassName = "RDSPluginWindow";
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    RegisterClass(&wc);

    hWnd = CreateWindowEx(
        0,
        "RDSPluginWindow",
        "RDS Plugin",
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU,
        CW_USEDEFAULT, CW_USEDEFAULT,
        400, 300,
        hOwner,
        NULL,
        hInst,
        NULL
    );

    // Create multiline edit control
    hEditControl = CreateWindowEx(
        WS_EX_CLIENTEDGE,
        "EDIT",
        "",
        WS_CHILD | WS_VISIBLE | WS_VSCROLL | 
        ES_LEFT | ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY,
        10, 10,
        370, 250,
        hWnd,
        NULL,
        hInst,
        NULL
    );

    // Set a default font
    HFONT hFont = CreateFont(16, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
                            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                            DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, "Segoe UI");
    SendMessage(hEditControl, WM_SETFONT, (WPARAM)hFont, TRUE);

    UpdateWindow(hWnd);
}

// Append text to the control
void AppendText(const char* text) {
    if (hEditControl != NULL) {
        int len = GetWindowTextLength(hEditControl);
        SendMessage(hEditControl, EM_SETSEL, len, len);
        SendMessageA(hEditControl, EM_REPLACESEL, FALSE, (LPARAM)text);
    }
}

// Set text (replace all)
void SetText(const char* text) {
    if (hEditControl != NULL) {
        SetWindowTextA(hEditControl, text);
    }
}

int lua_log(lua_State* localL) {
    const char* data = luaL_checkstring(localL, 1);
    AppendText(data);
    AppendText("\r\n");
    return 0;
}

int lua_MessageBox(lua_State* localL) {
    const char* data = luaL_checkstring(localL, 1);
    const char* title = luaL_checkstring(localL, 2);
    MessageBoxA(NULL, data, title, MB_OK | MB_TOPMOST);
    return 0;
}

void lua_call_command(const char* Cmd, const char* Param) {
    lua_getglobal(L, "command");

    if (lua_isfunction(L, -1)) {
        lua_pushstring(L, Cmd);
        lua_pushstring(L, Param);
        if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
            fprintf(stderr, "Lua error: %s at '%s'\n", lua_tostring(L, -1), "command");
            lua_pop(L, 1);
        }
    } else lua_pop(L, 1);
}

void lua_call_group() {
    lua_getglobal(L, "group");

    if (lua_isfunction(L, -1)) {
        lua_pushinteger(L, Group.RFU & 3); // TODO: find out if fuckass pira.cz meant msb or lsb, i have no clue what does "Bits: 0-1" mean
        lua_pushboolean(L, (Group.RFU & 0x100) >> 8); // just do lsb for now i guess
        lua_pushinteger(L, Group.Blk1);
        lua_pushinteger(L, Group.Blk2);
        lua_pushinteger(L, Group.Blk3);
        lua_pushinteger(L, Group.Blk4);
        if (lua_pcall(L, 6, 0, 0) != LUA_OK) {
            fprintf(stderr, "Lua error: %s at '%s'\n", lua_tostring(L, -1), "command");
            lua_pop(L, 1);
        }
    } else lua_pop(L, 1);
}

__declspec(dllexport) void __stdcall RDSGroup(TRDSGroup* PRDSGroup) {
    if (PRDSGroup == NULL) return;
    
    Group = *PRDSGroup;
    lua_call_group();
}

__declspec(dllexport) void __stdcall Command(const char* Cmd, const char* Param) {
    if (Cmd == NULL) return;
    if (_stricmp(Cmd, "EXIT") == 0) {
        if (hWnd != NULL) {
            DestroyWindow(hWnd);
            hWnd = NULL;
        }
        if(L != NULL) {
            lua_close(L);
            L = NULL;
        }
    } else if (_stricmp(Cmd, "CONFIGURE") == 0) {
        ShowWindow(hWnd, SW_SHOW);
    } else if (_stricmp(Cmd, "SHOW") == 0) {
        ShowWindow(hWnd, SW_SHOW);
    } else if (_stricmp(Cmd, "MINIMIZE") == 0) {
        ShowWindow(hWnd, SW_MINIMIZE);
    } else if (_stricmp(Cmd, "RESTORE") == 0) {
        ShowWindow(hWnd, SW_RESTORE);
    } else {
        lua_call_command(Cmd, Param);
    }
}

__declspec(dllexport) const char* __stdcall PluginName(void) {
    return "Lua Host";
}

__declspec(dllexport) int __stdcall Initialize(HANDLE hHandle, TDB* DBPointer) {
    CreatePluginWindow(hHandle);
    AppendText(LUA_COPYRIGHT);
    AppendText("\r\n");
    L = luaL_newstate();
    luaL_openlibs(L);
    lua_register(L, "message_box", lua_MessageBox);
    lua_register(L, "log", lua_log);

    char path[MAX_PATH];
    char fullPath[MAX_PATH];

    if (SUCCEEDED(SHGetFolderPathA(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, path))) {
        snprintf(fullPath, MAX_PATH, "%s\\RDS Spy\\script.lua", path);
    } else {
        MessageBoxA(NULL, "Could not get the local app data path", "Error", MB_ICONERROR | MB_OK | MB_TOPMOST);
        AppendText("Could not get the local app data path\r\n");
        return (int)hWnd;
    }

    char msg_buffer[255];
    if (luaL_loadfile(L, fullPath) != LUA_OK) {
        sprintf(msg_buffer, "Lua error loading file: %s\r\n", lua_tostring(L, -1));
        AppendText(msg_buffer);
        lua_pop(L, 1);
    } else {
        if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
            sprintf(msg_buffer, "Init error: %s\r\n", lua_tostring(L, -1));
            AppendText(msg_buffer);
            lua_pop(L, 1);
        }
    }

    return (int)hWnd;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    if (fdwReason == DLL_PROCESS_ATTACH)
    {
        hInst = hinstDLL;
        MessageBoxA(NULL, "DLL Loaded!", "Debug", MB_OK | MB_TOPMOST);
    }
    return TRUE;
}
