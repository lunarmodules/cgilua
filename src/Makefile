# $Id: Makefile,v 1.15 2004/08/26 09:20:57 tomas Exp $

T= clmain

include ../config

CGILUA_LUAS= lib/cgilua/cgilua.lua lib/cgilua/post.lua lib/cgilua/prep.lua lib/cgilua/readuntil.lua lib/cgilua/urlcode.lua
LIB_LUAS= lib/compat-5.1.lua lib/venv.lua
USR_LIB_LUAS= usr/lib/cookies.lua usr/lib/cl_ses.lua usr/lib/session.lua
CONF_LUAS= conf/cgilua.conf conf/error.conf conf/session.conf
MAIN= main.lua
LUAS= $(MAIN) $(CONF_LUAS) $(LIB_LUAS) $(CGILUA_LUAS) $(USR_LIB_LUAS)

cgi fcgi mod: $(LUAS)

cgiinstall fcgiinstall modinstall: $(LUAS)
	#mkdir -p $(CGILUA_DIR)
	#cp $(MAIN) $(CGILUA_DIR)
	#mkdir -p $(CGILUA_CONFDIR)
	#cp $(CONF_LUAS) $(CGILUA_CONFDIR)
	#mkdir -p $(CGILUA_LUADIR)
	#cp $(LIB_LUAS) $(CGILUA_LUADIR)
	mkdir -p $(LUA_DIR)
	cp $(LIB_LUAS) $(LUA_DIR)
	#mkdir -p $(CGILUA_CGILUADIR)
	#cp $(CGILUA_LUAS) $(CGILUA_CGILUADIR)
	#cp $(CGILUA_LUAS) $(CGILUA_LUADIR)
	mkdir -p $(CGILUA_DIR)
	cp $(CGILUA_LUAS) $(CGILUA_DIR)
	#mkdir -p $(CGILUA_USRLIBDIR)
	#cp $(USR_LIB_LUAS) $(CGILUA_USRLIBDIR)
	#cp $(USR_LIB_LUAS) $(CGILUA_LUADIR)
	cp $(USR_LIB_LUAS) $(CGILUA_DIR)
	mkdir -p $(CGILUA_TMPDIR)
	chmod a+w $(CGILUA_TMPDIR)

clean:

dist:
	mkdir -p $(DIST_DIR)
	cp $(MAIN) Makefile $(DIST_DIR)
	mkdir $(DIST_DIR)/conf
	cp $(CONF_LUAS) $(DIST_DIR)/conf/
	mkdir -p $(DIST_DIR)/lib/cgilua
	cp $(LIB_LUAS) $(DIST_DIR)/lib/
	cp $(CGILUA_LUAS) $(DIST_DIR)/lib/cgilua/
	mkdir -p $(DIST_DIR)/usr/lib
	cp $(USR_LIB_LUAS) $(DIST_DIR)/usr/lib/
