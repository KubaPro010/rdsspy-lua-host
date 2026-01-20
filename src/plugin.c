#include "api.h"
#include <stdio.h>
#include <string.h>

static TRDSGroup Group;

static HWND hWnd = NULL;
static HINSTANCE hInst = NULL;

static lua_State* L = NULL;

HWND hEditControl = NULL;
TDB* g_DBPointer = NULL;

HFONT g_hCurrentFont = NULL;

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

uint8_t console_mode = 0;
uint8_t stop_execution = 0;
uint8_t sticky = 0;
unsigned char workspaceFile[MAX_PATH] = "";

const char* int_to_string(int value) {
    static char buffer[16];
    snprintf(buffer, sizeof(buffer), "%d", value);
    return buffer;
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
        lua_pushinteger(L, Group.RFU & 3);
        lua_pushboolean(L, (Group.RFU & 0x100) >> 8);
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
        if(L != NULL) {
            lua_close(L);
            L = NULL;
        }
        if (hWnd != NULL) {
            DestroyWindow(hWnd);
            hWnd = NULL;
        }
    } else if (_stricmp(Cmd, "CONFIGURE") == 0 || _stricmp(Cmd, "SHOW") == 0 || _stricmp(Cmd, "RESTORE") == 0) ShowWindow(hWnd, SW_SHOW);
    else if (_stricmp(Cmd, "MINIMIZE") == 0) ShowWindow(hWnd, SW_HIDE);
    else if (_stricmp(Cmd, "SHOWHIDE") == 0) {
        if(IsWindowVisible(hWnd)) ShowWindow(hWnd, SW_HIDE);
        else ShowWindow(hWnd, SW_SHOW);
    } else if (_stricmp(Cmd, "OPENWORKSPACE") == 0) {
        if(hWnd != NULL) {
            int value = GetPrivateProfileIntA("luahost", "Visible", 0, Param);
            if(value == 1) ShowWindow(hWnd, SW_SHOW);
            else if(value == 0) ShowWindow(hWnd, SW_HIDE);
            int x = GetPrivateProfileIntA("luahost", "Left", 320, Param);
            int y = GetPrivateProfileIntA("luahost", "Top", 240, Param);
            SetWindowPos(hWnd, NULL, x, y, 0, 0, SWP_NOSIZE);
        }
        sticky = GetPrivateProfileIntA("luahost", "Stick", 0, Param);
        lua_call_command(Cmd, Param);
    } else if (_stricmp(Cmd, "SAVEWORKSPACE") == 0) {
        if(hWnd != NULL) {
            RECT rect;
            if (GetWindowRect(hWnd, &rect)) {
                WritePrivateProfileStringA("luahost", "Left", int_to_string(rect.left), Param);
                WritePrivateProfileStringA("luahost", "Top", int_to_string(rect.top), Param);
            }
            WritePrivateProfileStringA("luahost", "Stick", (sticky != 0) ? "1" : "0", Param);
            WritePrivateProfileStringA("luahost", "Visible", IsWindowVisible(hWnd) ? "1" : "0", Param);
        }
        memcpy(workspaceFile, Param, MAX_PATH);
        workspaceFile[MAX_PATH-1] = 0;
        lua_call_command(Cmd, Param);
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

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH) hInst = hinstDLL;
    return TRUE;
}
