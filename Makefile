# $Id: Makefile,v 1.39 2007/08/20 20:47:58 carregal Exp $

LUA_DIR= /usr/share/lua/5.1
CGILUA_DIR= $(LUA_DIR)/cgilua
CGILUA_LUAS= src/cgilua/cookies.lua src/cgilua/lp.lua src/cgilua/post.lua src/cgilua/readuntil.lua src/cgilua/serialize.lua src/cgilua/session.lua src/cgilua/urlcode.lua
ROOT_LUAS= src/cgilua/cgilua.lua
CONFIG_FILE= config.lua


install:
	mkdir -p $(CGILUA_DIR)
	cp $(CGILUA_LUAS) $(CGILUA_DIR)
	cp $(ROOT_LUAS) $(LUA_DIR)
	if [ ! -e $(CGILUA_DIR)/$(CONFIG_FILE) ] ; then cp src/cgilua/$(CONFIG_FILE) $(CGILUA_DIR); fi

clean:
