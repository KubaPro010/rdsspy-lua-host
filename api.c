#include "api.h"

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

unsigned char CharConv(unsigned char Ch) {
    if (Ch >= 128 && Ch < 255) {
        unsigned char conv = EBU[Ch - 128];
        if (conv != 0) return conv;
    }
    return Ch;
}

int lua_log(lua_State* localL) {
    if(console_mode != 0) return luaL_error(localL, "Invalid log");
    AppendText(luaL_checkstring(localL, 1));
    AppendText("\r\n");
    return 0;
}

int lua_set_console(lua_State* localL) {
    if(console_mode != 1) return luaL_error(localL, "Invalid log");
    if (hEditControl != NULL) SetWindowTextA(hEditControl, luaL_checkstring(localL, 1));
    return 0;
}

int lua_set_console_mode(lua_State* localL) {
    if (!lua_isboolean(localL, 1)) return luaL_typeerror(localL, 1, lua_typename(localL, LUA_TBOOLEAN));
    int mode = lua_toboolean(localL, 1);
    if (hEditControl != NULL) SetWindowTextA(hEditControl, "");
    console_mode = mode;
    return 0;
}

int lua_set_window_stick(lua_State* localL) {
    if (!lua_isboolean(localL, 1)) return luaL_typeerror(localL, 1, lua_typename(localL, LUA_TBOOLEAN));
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
    MessageBoxA(NULL, luaL_checkstring(localL, 1), luaL_checkstring(localL, 2), MB_OK | MB_TOPMOST);
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
    else return luaL_typeerror(localL, 1, lua_typename(localL, LUA_TSTRING));
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
    } else return luaL_typeerror(localL, 1, lua_typename(localL, LUA_TSTRING));
}