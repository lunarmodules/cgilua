# $Id: Makefile,v 1.3 2005/03/17 13:36:47 carregal Exp $

LUA_DIR= /usr/local/share/lua/5.0
CGILUA_DIR= $(LUA_DIR)/cgilua
V= 5.0RC
PKG= cgilua-$V
T= main
DIST_DIR= $(PKG)
CGILUA_LUAS= cgilua.lua cookies.lua lp.lua post.lua readuntil.lua serialize.lua session.lua urlcode.lua
CONFIG_FILE= config.lua

dist_dir:
	mkdir -p $(DIST_DIR)
	cp Makefile $(CGILUA_LUAS) $(CONFIG_FILE) $(DIST_DIR)

install:
	mkdir -p $(CGILUA_DIR)
	cp $(CGILUA_LUAS) $(CGILUA_DIR)
	if [ ! -e $(CGILUA_DIR)/$(CONFIG_FILE) ] ; then cp $(CONFIG_FILE) $(CGILUA_DIR); fi

clean:
