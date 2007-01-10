# $Id: Makefile,v 1.37 2007/01/10 20:48:49 mascarenhas Exp $

LUA_DIR= /usr/local/share/lua/5.1
CGILUA_DIR= $(LUA_DIR)/cgilua
CGILUA_LUAS= src/cgilua/cgilua.lua src/cgilua/cookies.lua src/cgilua/lp.lua src/cgilua/post.lua src/cgilua/readuntil.lua src/cgilua/serialize.lua src/cgilua/session.lua src/cgilua/urlcode.lua
CONFIG_FILE= config.lua


install:
	mkdir -p $(CGILUA_DIR)
	cp $(CGILUA_LUAS) $(CGILUA_DIR)
	ln -sf $(CGILUA_DIR)/cgilua.lua $(LUA_DIR)/cgilua.lua
	if [ ! -e $(CGILUA_DIR)/$(CONFIG_FILE) ] ; then cp src/cgilua/$(CONFIG_FILE) $(CGILUA_DIR); fi

clean:
