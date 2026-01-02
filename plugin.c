#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <shlobj.h>
#include <stdint.h>
#include "lua/lua.h"
#include "lua/lualib.h"
#include "lua/lauxlib.h"

typedef struct {
    uint16_t Year;
    uint8_t Month;
    uint8_t Day;
    uint8_t Hour;
    uint8_t Minute;
    uint8_t Second;
    uint8_t Centisecond;
    uint16_t RFU;
    int32_t Blk1;
    int32_t Blk2;
    int32_t Blk3;
    int32_t Blk4;
} TRDSGroup;

typedef struct {
    // fuckass delphi
    uint8_t len;
    uint8_t data[255];
} ShortString;

typedef struct {
    ShortString Key;
    ShortString Value;
} TRecord;

typedef struct {
    int32_t Count;
    TRecord Records[255];
} TDB;

static TRDSGroup Group;

static HWND hWnd = NULL;
static HINSTANCE hInst = NULL;

static lua_State* L = NULL;

static HWND hEditControl = NULL;
static TDB* g_DBPointer = NULL;

static HFONT g_hCurrentFont = NULL;
#define FONT_NAME "Segoe UI"

#define IDC_MAIN_BUTTON 101

#define WINDOW_HEIGHT 380
#define WINDOW_WIDTH 620
#define BUTTON_COUNT 7

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

#define EVENT_BUTTON(I) \
HWND hButton_event##I = CreateWindowEx( \
    0, "BUTTON", "Event " TOSTRING(I), \
    WS_TABSTOP | WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON | BS_NOTIFY, \
    10 + (75 * I), WINDOW_HEIGHT-62, \
    70, 30, hWnd, \
    (HMENU)(IDC_MAIN_BUTTON + I), hInst, NULL \
);

static const unsigned char EBU[127] = {
    0xE1, 'a', 0xE9, 'e', 0xED, 'i', 0xF3, 'o', 0xFA, 'u', 'N', 0xC7, 0xAA, 0xDF, 'I', 0x00,
    0xE2, 0xE4, 'e', 0xEB, 0xEE, 'i', 0xF4, 0xF6, 'u', 0xFC, 'n', 0xE7, 0xBA, 0x00, 'i', 0x00,
    0x00, 0x00, 0xA9, 0x89, 0x00, 0xEC, 0xF2, 0xF5, 0x00, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0xB1, 'I', 0xF1, 0xFB, 0xB5, '?', 0xF7, 0xB0, 0x00, 0x00, 0x00, 0xA7, 0x00,
    0xC1, 'A', 0xC9, 'E', 0xCD, 'I', 0xD3, 'O', 0xDA, 'U', 0xD8, 0xC8, 0x8A, 0x8E, 0xD0, 'L',
    0xC2, 0xC4, 'E', 0xCB, 0xCE, 'I', 0xD4, 0xD6, 'U', 0xDC, 0xF8, 0xE8, 0x9A, 0x9E, 0xF0, 'l',
    0x00, 0x00, 0x00, 0x00, 0x00, 0xDD, 0x00, 0x00, 0x00, 0x00, 0xC0, 0xC6, 0x8C, 0x8F, 0x00, 0x00,
    0x00, 0x00, 0x00, 0xFD, 0x00, 0x00, 0x00, 0x00, 0xE0, 0xE6, 0x9C, 0x9F, 0x00
};

static unsigned short console_mode = 0;
static unsigned short stop_execution = 0;
static unsigned short sticky = 0;
static unsigned char workspaceFile[MAX_PATH] = "";

const char* int_to_string(int value) {
    static char buffer[16];
    snprintf(buffer, sizeof(buffer), "%d", value);
    return buffer;
}

unsigned char CharConv(unsigned char Ch) {
    if (Ch >= 128 && Ch < 255) {
        unsigned char conv = EBU[Ch - 128];
        if (conv != 0) return conv;
    }
    return Ch;
}

void InitLua();
void lua_event(int event);
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg)
    {
        case WM_CLOSE:
            ShowWindow(hwnd, SW_HIDE);
            return 0;
        case WM_COMMAND:
            if (HIWORD(wParam) == BN_CLICKED || HIWORD(wParam) == BN_DOUBLECLICKED)
            {
                int controlId = LOWORD(wParam);

                int offset = 0;
                if(HIWORD(wParam) == BN_DOUBLECLICKED) offset = BUTTON_COUNT;

                if (controlId == IDC_MAIN_BUTTON && HIWORD(wParam) == BN_DOUBLECLICKED) InitLua();
                else if (controlId > IDC_MAIN_BUTTON && controlId <= IDC_MAIN_BUTTON + BUTTON_COUNT) lua_event((controlId - IDC_MAIN_BUTTON) + offset);
            }
            break;
        case WM_DESTROY:
            hWnd = NULL;
            return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

void CreatePluginWindow(HWND hOwner) {
    WNDCLASS wc = {0};
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInst;
    wc.lpszClassName = "LuaHostPlugin";
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    RegisterClass(&wc);

    hWnd = CreateWindowEx(
        0,
        "LuaHostPlugin",
        "Lua Host Console",
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU,
        CW_USEDEFAULT, CW_USEDEFAULT,
        WINDOW_WIDTH, WINDOW_HEIGHT,
        hOwner,
        NULL,
        hInst,
        NULL
    );

    hEditControl = CreateWindowEx(
        WS_EX_CLIENTEDGE, "EDIT", "",
        WS_CHILD | WS_VISIBLE | WS_VSCROLL |
        ES_LEFT | ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY,
        10, 10, WINDOW_WIDTH-25, WINDOW_HEIGHT-75,
        hWnd, NULL, hInst, NULL
    );

    HWND hButton = CreateWindowEx(
        0, "BUTTON", "Reload",
        WS_TABSTOP | WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON | BS_NOTIFY,
        10, WINDOW_HEIGHT-62,
        70, 30, hWnd,
        (HMENU)IDC_MAIN_BUTTON, hInst, NULL
    );

    EVENT_BUTTON(1)
    EVENT_BUTTON(2)
    EVENT_BUTTON(3)
    EVENT_BUTTON(4)
    EVENT_BUTTON(5)
    EVENT_BUTTON(6)
    EVENT_BUTTON(7)

    HFONT hFont = CreateFont(18, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, FONT_NAME);
    SendMessage(hEditControl, WM_SETFONT, (WPARAM)hFont, TRUE);
    SendMessage(hButton, WM_SETFONT, (WPARAM)hFont, TRUE);
    SendMessage(hButton_event1, WM_SETFONT, (WPARAM)hFont, TRUE);
    SendMessage(hButton_event2, WM_SETFONT, (WPARAM)hFont, TRUE);
    SendMessage(hButton_event3, WM_SETFONT, (WPARAM)hFont, TRUE);
    SendMessage(hButton_event4, WM_SETFONT, (WPARAM)hFont, TRUE);
    SendMessage(hButton_event5, WM_SETFONT, (WPARAM)hFont, TRUE);
    SendMessage(hButton_event6, WM_SETFONT, (WPARAM)hFont, TRUE);
    SendMessage(hButton_event7, WM_SETFONT, (WPARAM)hFont, TRUE);

    HICON hIconBig = (HICON)SendMessage(hOwner, WM_GETICON, ICON_BIG, 0);
    HICON hIconSmall = (HICON)SendMessage(hOwner, WM_GETICON, ICON_SMALL, 0);
    if (!hIconBig) hIconBig = (HICON)GetClassLongPtr(hOwner, GCLP_HICON);
    if (!hIconSmall) hIconSmall = (HICON)GetClassLongPtr(hOwner, GCLP_HICONSM);
    SendMessage(hWnd, WM_SETICON, ICON_BIG, (LPARAM)hIconBig);
    SendMessage(hWnd, WM_SETICON, ICON_SMALL, (LPARAM)hIconSmall);

    UpdateWindow(hWnd);
}

void AppendText(const char* text) {
    if (hEditControl != NULL) {
        int len = GetWindowTextLength(hEditControl);
        SendMessage(hEditControl, EM_SETSEL, len, len);
        SendMessageA(hEditControl, EM_REPLACESEL, FALSE, (LPARAM)text);
    }
}

void SetText(const char* text) {
    if (hEditControl != NULL) SetWindowTextA(hEditControl, text);
}

int lua_log(lua_State* localL) {
    if(console_mode != 0) return luaL_error(localL, "Invalid log");
    const char* data = luaL_checkstring(localL, 1);
    AppendText(data);
    AppendText("\r\n");
    return 0;
}

int lua_set_console(lua_State* localL) {
    if(console_mode != 1) return luaL_error(localL, "Invalid log");
    const char* data = luaL_checkstring(localL, 1);
    SetText(data);
    return 0;
}

int lua_set_console_mode(lua_State* localL) {
    if (!lua_isboolean(localL, 1)) return luaL_error(localL, "boolean expected, got %s", luaL_typename(localL, 1));
    int mode = lua_toboolean(localL, 1);
    SetText("");
    console_mode = mode;
    return 0;
}

int lua_set_window_stick(lua_State* localL) {
    if (!lua_isboolean(localL, 1)) return luaL_error(localL, "boolean expected, got %s", luaL_typename(localL, 1));
    sticky = lua_toboolean(localL, 1);
    return 0;
}

int lua_get_window_stick(lua_State* localL) {
    lua_pushboolean(localL, sticky);
    return 1;
}

int lua_set_font_size(lua_State* localL) {
    int size = luaL_checkinteger(localL, 1);

    HFONT hNewFont = CreateFont(size, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, FONT_NAME);

    if (hNewFont && hEditControl) {
        SendMessage(hEditControl, WM_SETFONT, (WPARAM)hNewFont, TRUE);

        if (g_hCurrentFont != NULL) DeleteObject(g_hCurrentFont);

        g_hCurrentFont = hNewFont;
    }

    return 0;
}

int lua_MessageBox(lua_State* localL) {
    const char* data = luaL_checkstring(localL, 1);
    const char* title = luaL_checkstring(localL, 2);
    MessageBoxA(NULL, data, title, MB_OK | MB_TOPMOST);
    return 0;
}

int lua_ReadValue(lua_State* localL) {
    if (g_DBPointer == NULL) {
        lua_pushnil(localL);
        return 1;
    }

    const char* key = luaL_checkstring(localL, 1);
    ShortString skey;
    skey.len = strlen(key);
    if (skey.len > 255) skey.len = 255;
    memcpy(skey.data, key, skey.len);

    int count = g_DBPointer->Count;
    if (count > 255) count = 255;

    for (int i = 0; i < count; i++) {
        if (g_DBPointer->Records[i].Key.len == skey.len &&
            memcmp(g_DBPointer->Records[i].Key.data, skey.data, skey.len) == 0) {
            lua_pushlstring(localL, g_DBPointer->Records[i].Value.data, g_DBPointer->Records[i].Value.len);
            return 1;
        }
    }

    lua_pushnil(localL);
    return 1;
}

int lua_ReadRecord(lua_State* localL) {
    if (g_DBPointer == NULL) {
        lua_pushnil(localL);
        lua_pushnil(localL);
        return 2;
    }

    int index = luaL_checkinteger(localL, 1);

    if (index < 0 || index >= g_DBPointer->Count || index >= 255) {
        lua_pushnil(localL);
        lua_pushnil(localL);
        return 2;
    }

    lua_pushlstring(localL, g_DBPointer->Records[index].Key.data, g_DBPointer->Records[index].Key.len);
    lua_pushlstring(localL, g_DBPointer->Records[index].Value.data, g_DBPointer->Records[index].Value.len);
    return 2;
}

int lua_AddValue(lua_State* localL) {
    if (g_DBPointer == NULL) return 0;

    const char* key = luaL_checkstring(localL, 1);
    const char* value = luaL_checkstring(localL, 2);

    ShortString skey, svalue;
    skey.len = strlen(key);
    if (skey.len > 255) skey.len = 255;
    memcpy(skey.data, key, skey.len);

    svalue.len = strlen(value);
    if (svalue.len > 252) {
        svalue.len = 252;
        memcpy(svalue.data, value, 252);
        memcpy(svalue.data + 252, "...", 3);
        svalue.len = 255;
    } else memcpy(svalue.data, value, svalue.len);

    int count = g_DBPointer->Count;
    if (count > 255) count = 255;

    for (int i = 0; i < count; i++) {
        if (g_DBPointer->Records[i].Key.len == skey.len &&
            memcmp(g_DBPointer->Records[i].Key.data, skey.data, skey.len) == 0) {
            g_DBPointer->Records[i].Value = svalue;
            return 0;
        }
    }

    if (count < 254) {
        g_DBPointer->Records[count].Key = skey;
        g_DBPointer->Records[count].Value = svalue;
        g_DBPointer->Count = count + 1;
    } else if (_stricmp(key, "COMMAND") == 0) {
        g_DBPointer->Records[254].Key = skey;
        g_DBPointer->Records[254].Value = svalue;
    }

    return 0;
}

int lua_ResetValues(lua_State* localL) {
    if (g_DBPointer == NULL) return 0;
    g_DBPointer->Count = 0;
    return 0;
}

int lua_CountRecords(lua_State* localL) {
    if (g_DBPointer == NULL) {
        lua_pushinteger(localL, 0);
        return 1;
    }

    int count = g_DBPointer->Count;
    if (count > 255) count = 255;
    lua_pushinteger(localL, count);
    return 1;
}

int lua_CharConv(lua_State* localL) {
    int ch = luaL_checkinteger(localL, 1);
    lua_pushinteger(localL, CharConv((unsigned char)ch));
    return 1;
}

int lua_SaveString(lua_State* localL) {
    const char* section = luaL_checkstring(localL, 2);
    const char* key = luaL_checkstring(localL, 3);
    const char* value = luaL_checkstring(localL, 4);
    if (lua_isstring(localL, 1)) {
        const char* filename = luaL_checkstring(localL, 1);

        char path[MAX_PATH];
        if (SUCCEEDED(SHGetFolderPathA(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, path))) {
            char fullPath[MAX_PATH];
            snprintf(fullPath, MAX_PATH, "%s\\RDS Spy\\%s", path, filename);
            WritePrivateProfileStringA(section, key, value, fullPath);
        }
    } else if(lua_isnil(localL, 1)) WritePrivateProfileStringA(section, key, value, workspaceFile);
    else luaL_typeerror(L, 1, lua_typename(L, LUA_TSTRING));
    return 0;
}

int lua_LoadString(lua_State* localL) {
    const char* section = luaL_checkstring(localL, 2);
    const char* key = luaL_checkstring(localL, 3);
    const char* defaultValue = luaL_optstring(localL, 4, "");

    char buffer[1024];
    if (lua_isstring(localL, 1)) {
        const char* filename = luaL_checkstring(localL, 1);
        char path[MAX_PATH];

        if (SUCCEEDED(SHGetFolderPathA(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, path))) {
            char fullPath[MAX_PATH];
            snprintf(fullPath, MAX_PATH, "%s\\RDS Spy\\%s", path, filename);
            GetPrivateProfileStringA(section, key, defaultValue, buffer, 1024, fullPath);
            lua_pushstring(localL, buffer);
        } else lua_pushstring(localL, defaultValue);
        return 1;
    } else if(lua_isnil(localL, 1)) {
        GetPrivateProfileStringA(section, key, defaultValue, buffer, 1024, workspaceFile);
        lua_pushstring(localL, buffer);
        return 1;
    } else luaL_typeerror(L, 1, lua_typename(L, LUA_TSTRING));
    return 0;
}

void lua_call_command(const char* Cmd, const char* Param) {
    if(stop_execution != 0) return;
    lua_getglobal(L, "command");

    if (lua_isfunction(L, -1)) {
        lua_pushstring(L, Cmd);
        lua_pushstring(L, Param);
        if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
            char msg_buffer[255];
            snprintf(msg_buffer, sizeof(msg_buffer), "Lua error: %s at '%s'\n", lua_tostring(L, -1), "command");
            AppendText(msg_buffer);
            lua_pop(L, 1);
            stop_execution = 1;
        }
    } else lua_pop(L, 1);
}

void lua_call_group() {
    if(stop_execution != 0) return;
    lua_getglobal(L, "group");

    if (lua_isfunction(L, -1)) {
        lua_pushinteger(L, Group.RFU & 3); // TODO: find out if fuckass pira.cz meant msb or lsb, i have no clue what does "Bits: 0-1" mean
        lua_pushboolean(L, (Group.RFU & 0x100) >> 8); // just do lsb for now i guess
        lua_pushinteger(L, Group.Blk1);
        lua_pushinteger(L, Group.Blk2);
        lua_pushinteger(L, Group.Blk3);
        lua_pushinteger(L, Group.Blk4);

        lua_newtable(L);
        lua_pushinteger(L, Group.Year);
        lua_setfield(L, -2, "year");
        lua_pushinteger(L, Group.Month);
        lua_setfield(L, -2, "month");
        lua_pushinteger(L, Group.Day);
        lua_setfield(L, -2, "day");
        lua_pushinteger(L, Group.Hour);
        lua_setfield(L, -2, "hour");
        lua_pushinteger(L, Group.Minute);
        lua_setfield(L, -2, "minute");
        lua_pushinteger(L, Group.Second);
        lua_setfield(L, -2, "second");
        lua_pushinteger(L, Group.Centisecond);
        lua_setfield(L, -2, "centisecond");

        if (lua_pcall(L, 7, 0, 0) != LUA_OK) {
            char msg_buffer[255];
            snprintf(msg_buffer, sizeof(msg_buffer), "Lua error: %s at '%s'\r\n", lua_tostring(L, -1), "group");
            AppendText(msg_buffer);
            lua_pop(L, 1);
            stop_execution = 1;
        }
    } else lua_pop(L, 1);
}

void lua_event(int event) {
    if(stop_execution != 0) return;
    lua_getglobal(L, "event");

    if (lua_isfunction(L, -1)) {
        lua_pushinteger(L, event);
        if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
            char msg_buffer[255];
            snprintf(msg_buffer, sizeof(msg_buffer), "Lua error: %s at '%s'\r\n", lua_tostring(L, -1), "event");
            AppendText(msg_buffer);
            lua_pop(L, 1);
            stop_execution = 1;
        }
    } else lua_pop(L, 1);
}

__declspec(dllexport) void WINAPI RDSGroup(TRDSGroup* PRDSGroup) {
    if (PRDSGroup == NULL) return;

    Group = *PRDSGroup;
    lua_call_group();
}

__declspec(dllexport) void WINAPI Command(const char* Cmd, const char* Param) {
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
    } else if (_stricmp(Cmd, "CONFIGURE") == 0 || _stricmp(Cmd, "SHOW") == 0 || _stricmp(Cmd, "RESTORE") == 0) ShowWindow(hWnd, SW_SHOW);
    else if (_stricmp(Cmd, "MINIMIZE") == 0) ShowWindow(hWnd, SW_HIDE);
    else if (_stricmp(Cmd, "SHOWHIDE") == 0) {
        if(IsWindowVisible(hWnd)) ShowWindow(hWnd, SW_HIDE);
        else ShowWindow(hWnd, SW_SHOW);
    }
    else if (_stricmp(Cmd, "OPENWORKSPACE") == 0) {
        if(hWnd != NULL) {
            int value = GetPrivateProfileIntA("luahost", "Visible", 0, Param);
            if(value == 1) ShowWindow(hWnd, SW_SHOW);
            else if(value == 0) ShowWindow(hWnd, SW_HIDE);
            int x = GetPrivateProfileIntA("luahost", "Left", 320, Param);
            int y = GetPrivateProfileIntA("luahost", "Top", 240, Param);
            SetWindowPos(hWnd, NULL, x, y, 0, 0, SWP_NOSIZE);
        }
        sticky = GetPrivateProfileIntA("luahost", "Stick", 0, Param);
        lua_call_command(Cmd, Param); // still call
    } else if (_stricmp(Cmd, "SAVEWORKSPACE") == 0) {
        if(hWnd != NULL) {
            RECT rect; // get rect
            if (GetWindowRect(hWnd, &rect)) {
                WritePrivateProfileStringA("luahost", "Left", int_to_string(rect.left), Param);
                WritePrivateProfileStringA("luahost", "Top", int_to_string(rect.top), Param);
            }
            WritePrivateProfileStringA("luahost", "Stick", (sticky != 0) ? "1" : "0", Param);
            WritePrivateProfileStringA("luahost", "Visible", IsWindowVisible(hWnd) ? "1" : "0", Param);
        }
        memcpy(workspaceFile, Param, MAX_PATH);
        workspaceFile[MAX_PATH-1] = 0;
        lua_call_command(Cmd, Param); // still call
    } else if (_stricmp(Cmd, "LUASCRIPT") == 0) { // custom
        char msg_buffer[255];
        if (luaL_loadfile(L, Param) != LUA_OK) {
            snprintf(msg_buffer, sizeof(msg_buffer), "Lua error loading file: %s\r\n", lua_tostring(L, -1));
            AppendText(msg_buffer);
            lua_pop(L, 1);
            stop_execution = 1;
        } else {
            if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
                snprintf(msg_buffer, sizeof(msg_buffer), "Init error: %s\r\n", lua_tostring(L, -1));
                AppendText(msg_buffer);
                lua_pop(L, 1);
                stop_execution = 1;
            }
        }
    } else if(_stricmp(Cmd, "MOVEX") == 0) {
        if(sticky != 0) {
            RECT rect; // get rect
            if (GetWindowRect(hWnd, &rect)) SetWindowPos(hWnd, NULL, rect.left+atoi(Param), rect.top, 0, 0, SWP_NOSIZE);
        }
    } else if(_stricmp(Cmd, "MOVEY") == 0) {
        if(sticky != 0) {
            RECT rect; // get rect
            if (GetWindowRect(hWnd, &rect)) SetWindowPos(hWnd, NULL, rect.left, rect.top+atoi(Param), 0, 0, SWP_NOSIZE);
        }
    } else lua_call_command(Cmd, Param);
}

__declspec(dllexport) const char* WINAPI PluginName(void) { return "Lua Host"; }

void InitLua() {
    if(L != NULL) {
        lua_close(L);
        L = NULL;
    }
    L = luaL_newstate();
    luaL_openlibs(L);
    lua_register(L, "set_font_size", lua_set_font_size);
    lua_register(L, "message_box", lua_MessageBox);
    lua_register(L, "log", lua_log);
    lua_register(L, "set_console", lua_set_console);
    lua_register(L, "set_console_mode", lua_set_console_mode);
    lua_register(L, "set_window_stick", lua_set_window_stick);
    lua_register(L, "get_window_stick", lua_get_window_stick);

    lua_pushinteger(L, BUTTON_COUNT);
    lua_setglobal(L, "event_count");

    lua_newtable(L);

    lua_pushcfunction(L, lua_ReadValue);
    lua_setfield(L, -2, "read_value");

    lua_pushcfunction(L, lua_ReadRecord);
    lua_setfield(L, -2, "read_record");

    lua_pushcfunction(L, lua_AddValue);
    lua_setfield(L, -2, "add_value");

    lua_pushcfunction(L, lua_ResetValues);
    lua_setfield(L, -2, "reset_values");

    lua_pushcfunction(L, lua_CountRecords);
    lua_setfield(L, -2, "count_records");

    lua_pushcfunction(L, lua_CharConv);
    lua_setfield(L, -2, "char_conv");

    lua_pushcfunction(L, lua_SaveString);
    lua_setfield(L, -2, "save_string");

    lua_pushcfunction(L, lua_LoadString);
    lua_setfield(L, -2, "load_string");

    lua_setglobal(L, "db");

    console_mode = 0;
    stop_execution = 0;

    char path[MAX_PATH];
    char fullPath[MAX_PATH];

    if (SUCCEEDED(SHGetFolderPathA(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, path))) snprintf(fullPath, MAX_PATH, "%s\\RDS Spy\\script.lua", path);
    else {
        MessageBoxA(NULL, "Could not get the local app data path", "Error", MB_ICONERROR | MB_OK | MB_TOPMOST);
        AppendText("Could not get the local app data path\r\n");
        return;
    }

    char msg_buffer[255];
    if (luaL_loadfile(L, fullPath) != LUA_OK) {
        snprintf(msg_buffer, sizeof(msg_buffer), "Lua error loading file: %s\r\n", lua_tostring(L, -1));
        AppendText(msg_buffer);
        lua_pop(L, 1);
        stop_execution = 1;
    } else {
        if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
            snprintf(msg_buffer, sizeof(msg_buffer), "Lua error: %s\r\n", lua_tostring(L, -1));
            AppendText(msg_buffer);
            lua_pop(L, 1);
            stop_execution = 1;
        }
    }
}

__declspec(dllexport) int WINAPI Initialize(HANDLE hHandle, TDB* DBPointer) {
    CreatePluginWindow(hHandle);
    AppendText(LUA_COPYRIGHT);
    AppendText("\r\n");
    g_DBPointer = DBPointer;
    InitLua();

    return (int)hWnd;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    if (fdwReason == DLL_PROCESS_ATTACH) hInst = hinstDLL;
    return TRUE;
}
