# $Id: Makefile,v 1.1 2005/03/08 21:04:51 carregal Exp $

T= main
DIST_DIR= ../$(PKG)/$T

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
