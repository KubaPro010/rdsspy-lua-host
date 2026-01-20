#pragma once

#include <windows.h>
#include <shlobj.h>
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "types.h"

extern HFONT g_hCurrentFont;
#define FONT_NAME "Segoe UI"

extern HWND hEditControl;
extern uint8_t console_mode;
extern uint8_t sticky;
extern TDB* g_DBPointer;
extern unsigned char workspaceFile[MAX_PATH];

int lua_log(lua_State* localL);
int lua_set_console(lua_State* localL);
int lua_set_console_mode(lua_State* localL);
int lua_set_window_stick(lua_State* localL);
int lua_get_window_stick(lua_State* localL);
int lua_set_font_size(lua_State* localL);
int lua_MessageBox(lua_State* localL);
int lua_ReadValue(lua_State* localL);
int lua_ReadRecord(lua_State* localL);
int lua_AddValue(lua_State* localL);
int lua_ResetValues(lua_State* localL);
int lua_CountRecords(lua_State* localL);
int lua_CharConv(lua_State* localL);
int lua_SaveString(lua_State* localL);
int lua_LoadString(lua_State* localL);

extern void AppendText(const char* text);