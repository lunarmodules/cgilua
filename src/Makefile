# $Id: Makefile,v 1.24 2004/11/30 15:11:36 tomas Exp $

T= clmain

include ../config

CGILUA_LUAS= cgilua/cgilua.lua cgilua/cookies.lua cgilua/post.lua cgilua/prep.lua cgilua/readuntil.lua cgilua/serialize.lua cgilua/session.lua cgilua/urlcode.lua
CONFIG_FILE= config.lua
LIB_LUAS= $(COMPAT_DIR)/compat-5.1.lua venv.lua
LUAS= $(LIB_LUAS) $(CGILUA_LUAS)

cgi fcgi mod: $(LUAS)

cgiinstall fcgiinstall modinstall: $(LUAS)
	mkdir -p $(LUA_DIR)
	cp $(LIB_LUAS) $(LUA_DIR)
	mkdir -p $(CGILUA_DIR)
	cp $(CGILUA_LUAS) $(CGILUA_DIR)
	if [ ! -e $(CGILUA_DIR)/$(CONFIG_FILE) ] ; then cp cgilua/$(CONFIG_FILE) $(CGILUA_DIR); fi
	mkdir -p $(CGILUA_TMPDIR)
	chmod a+w $(CGILUA_TMPDIR)

clean:

dist dist_dir:
	mkdir -p $(DIST_DIR)
	cp Makefile $(DIST_DIR)
	cp venv.lua $(DIST_DIR)
	mkdir -p $(DIST_DIR)/cgilua
	cp $(CGILUA_LUAS) $(DIST_DIR)/cgilua/
