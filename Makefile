LUA_LPATH=/usr/local/share/lua/5.1
LUA_CPATH=/usr/local/lib/lua/5.1

install:
	mkdir -p      $(LUA_LPATH)/tossam
	cp tossam.lua $(LUA_LPATH)
	cp codec.lua  $(LUA_LPATH)/tossam
	cp serial.lua $(LUA_LPATH)/tossam
