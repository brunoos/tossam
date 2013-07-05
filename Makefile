LUA_IDIR=-I$(HOME)/local/lua-5.1/include
SF_IDIR=-I$(TOSROOT)/support/sdk/c/sf
SF_LDIR=-L$(TOSROOT)/support/sdk/c/sf

LUA_LPATH=$(HOME)/local/lua-5.1/modules/lua
LUA_CPATH=$(HOME)/local/lua-5.1/modules/lib
#LUA_LPATH=/usr/local/share/lua/5.1
#LUA_CPATH=/usr/local/lib/lua/5.1

LIBS=-lmote
CFLAGS=-shared -fPIC -Wall $(LUA_IDIR)
SF_FLAGS=$(SF_IDIR) $(SF_LDIR)

CC=gcc

all: serial.so

serial.so: serial.c
	$(CC) $(CFLAGS) $(SF_FLAGS) -o $@ $< $(LIBS)

install:
	mkdir -p      $(LUA_LPATH)/tossam
	mkdir -p      $(LUA_CPATH)/tossam
	cp tossam.lua $(LUA_LPATH)
	cp codec.lua  $(LUA_LPATH)/tossam
	cp serial.so  $(LUA_CPATH)/tossam

clean:
	rm -f *.so
