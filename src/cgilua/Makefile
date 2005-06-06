# $Id: Makefile,v 1.4 2005/06/06 20:30:57 tomas Exp $

LUA_DIR= /usr/local/share/lua/5.0
CGILUA_DIR= $(LUA_DIR)/cgilua
CGILUA_LUAS= cgilua.lua cookies.lua lp.lua post.lua readuntil.lua serialize.lua session.lua urlcode.lua
CONFIG_FILE= config.lua


install:
	mkdir -p $(CGILUA_DIR)
	cp $(CGILUA_LUAS) $(CGILUA_DIR)
	if [ ! -e $(CGILUA_DIR)/$(CONFIG_FILE) ] ; then cp $(CONFIG_FILE) $(CGILUA_DIR); fi

clean:
