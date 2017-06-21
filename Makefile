LUA_LPATH=/usr/local/share/lua/5.1

install:
	mkdir -p  $(LUA_LPATH)/tossam
	cp tossam.lua        $(LUA_LPATH)
	cp tossam/codec.lua  $(LUA_LPATH)/tossam
	cp tossam/hdlc.lua   $(LUA_LPATH)/tossam
	cp tossam/serial.lua $(LUA_LPATH)/tossam
	cp tossam/sf.lua     $(LUA_LPATH)/tossam
