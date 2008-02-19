# $Id: Makefile,v 1.48 2008/02/19 19:32:55 mascarenhas Exp $

# Default prefix
PREFIX= /usr/local

# System's lua directory (where Lua libraries are installed)
LUA_DIR= $(PREFIX)/share/lua/5.1

CGILUA_DIR= $(LUA_DIR)/cgilua
CGILUA_LUAS= src/cgilua/authentication.lua src/cgilua/cookies.lua src/cgilua/dispatcher.lua src/cgilua/loader.lua src/cgilua/lp.lua src/cgilua/mime.lua src/cgilua/post.lua src/cgilua/readuntil.lua src/cgilua/serialize.lua src/cgilua/session.lua src/cgilua/urlcode.lua
ROOT_LUAS= src/cgilua/cgilua.lua

install:
	mkdir -p $(CGILUA_DIR)
	cp $(CGILUA_LUAS) $(CGILUA_DIR)
	cp $(ROOT_LUAS) $(LUA_DIR)

clean:

