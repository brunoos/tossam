#include <string.h>
#include <lua.h>
#include <lauxlib.h>

#include <serialsource.h>
#include <serialpacket.h>

#define TOSSAM_META "TOSSAM::META"

typedef struct tossam_source_s {
  serial_source src;
} tossam_source_t;

static int tossam_open(lua_State *L)
{
  int baud;
  int non_blocking;
  const char *dev;
  tossam_source_t *udata;
  dev = luaL_checkstring(L, 1);
  baud = luaL_checkint(L, 2);
  luaL_checktype(L, 3, LUA_TBOOLEAN);
  non_blocking = lua_toboolean(L, 3);
  udata = (tossam_source_t*)lua_newuserdata(L, sizeof(tossam_source_t));
  udata->src = open_serial_source(dev, baud, non_blocking, NULL);
  if (udata->src == NULL) {
    lua_pushnil(L);
    lua_pushstring(L, "Could not open device");
    return 2;
  }
  luaL_getmetatable(L, TOSSAM_META);
  lua_setmetatable(L, -2);
  return 1;
}

static int tossam_close(lua_State *L)
{
  tossam_source_t *udata = (tossam_source_t*)luaL_checkudata(L, 1, TOSSAM_META);
  if (udata->src != NULL)
    close_serial_source(udata->src);
  udata->src = NULL;
  return 0;
}

static int tossam_read(lua_State *L)
{
  int len;
  void *pack;
  tossam_source_t *udata = (tossam_source_t*)luaL_checkudata(L, 1, TOSSAM_META);
  pack = read_serial_packet(udata->src, &len);
  if (pack)
    lua_pushlstring(L, (const char*)pack, len);
  else
    lua_pushnil(L);
  return 1;
}

static int tossam_write(lua_State *L)
{
  tossam_source_t *udata = (tossam_source_t*)luaL_checkudata(L, 1, TOSSAM_META);
  const char *pack = luaL_checkstring(L, 2);
  int len = lua_objlen(L, 2);
  if (write_serial_packet(udata->src, (const void*)pack, len))
    lua_pushboolean(L, 0);
  else
    lua_pushboolean(L, 1);
  return 1;
}

static int tossam_baud(lua_State *L)
{
  char *rate = (char*)luaL_checkstring(L, 1);
  int baud = platform_baud_rate(rate);
  if (baud == -1) {
    lua_pushnil(L);
    lua_pushstring(L, "Invalid baud rate");
    return 2;
  }
  lua_pushnumber(L, baud);
  return 1;
}

static int tossam_getfd(lua_State *L)
{
  tossam_source_t *udata = (tossam_source_t*)luaL_checkudata(L, 1, TOSSAM_META);
  lua_pushnumber(L, serial_source_fd(udata->src));
  return 1;
}

static luaL_Reg funcs[] = {
  {"baud",  tossam_baud},
  {"close", tossam_close},
  {"getfd", tossam_getfd},
  {"open",  tossam_open},
  {"read",  tossam_read},
  {"write", tossam_write},
  {NULL,    NULL}
};

static luaL_Reg meta[] = {
  {"__gc",  tossam_close},
  {NULL,    NULL}
};

LUALIB_API int luaopen_tossam_serial(lua_State *L)
{
  luaL_newmetatable(L, TOSSAM_META);
  luaL_register(L, NULL, meta);
  luaL_register(L, "tossam.serial", funcs);
  return 1;
}
