# $Id: Makefile,v 1.16 2004/08/27 16:08:44 tomas Exp $

T= clmain

include ../config

CGILUA_LUAS= cgilua/cgilua.lua cgilua/cl_ses.lua cgilua/cookies.lua cgilua/post.lua cgilua/prep.lua cgilua/readuntil.lua cgilua/session.lua cgilua/urlcode.lua
LIB_LUAS= compat-5.1.lua venv.lua
CONF_LUAS= conf/cgilua.conf conf/error.conf conf/session.conf
LUAS= $(CONF_LUAS) $(LIB_LUAS) $(CGILUA_LUAS)

cgi fcgi mod: $(LUAS)

cgiinstall fcgiinstall modinstall: $(LUAS)
	mkdir -p $(LUA_DIR)
	cp $(LIB_LUAS) $(LUA_DIR)
	mkdir -p $(CGILUA_DIR)
	cp $(CGILUA_LUAS) $(CGILUA_DIR)
	mkdir -p $(CGILUA_TMPDIR)
	chmod a+w $(CGILUA_TMPDIR)

clean:

dist:
	mkdir -p $(DIST_DIR)
	cp Makefile $(DIST_DIR)
	cp $(LIB_LUAS) $(DIST_DIR)
	mkdir $(DIST_DIR)/conf
	cp $(CONF_LUAS) $(DIST_DIR)/conf/
	mkdir -p $(DIST_DIR)/cgilua
	cp $(CGILUA_LUAS) $(DIST_DIR)/cgilua/
