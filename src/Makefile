# $Id: Makefile,v 1.11 2004/07/20 12:02:09 tomas Exp $

T= clmain

include ../config

LUA_LIBS= cgilua.lua post.lua prep.lua readuntil.lua urlcode.lua venv.lua
USR_LIBS= cookies.lua session.lua cl_ses.lua
CONF= cgilua.conf
T_CONF= t_cgilua.conf
MAIN= main.lua
T_MAIN= t_main.lua
LUAS= $(MAIN) $(CONF) $(LUA_LIBS) $(USR_LIBS)
SRCS= $(T_MAIN) $(T_CONF) $(LUA_LIBS) $(USR_LIBS)

cgi fcgi mod: $(LUAS)

cgiinstall fcgiinstall modinstall: $(LUAS)
	mkdir -p $(CGILUA_DIR)
	cp -i $(MAIN) $(CGILUA_DIR)
	mkdir -p $(CGILUA_CONFDIR)
	cp -i $(CONF) $(CGILUA_CONF)
	mkdir -p $(CGILUA_LIBDIR)
	cp $(LUA_LIBS) $(CGILUA_LIBDIR)
	mkdir -p $(CGILUA_USRLIBDIR)
	cp $(USR_LIBS) $(CGILUA_USRLIBDIR)
	mkdir -p $(CGILUA_TMPDIR)
	chmod a+w $(CGILUA_TMPDIR)

$(CONF): $(T_CONF)
	sed -e "s|CGILUA_DIR|$(CGILUA_DIR)|" < $(T_CONF) > $@

$(MAIN): $(T_MAIN)
	sed -e "s|CGILUA_DIR|$(CGILUA_DIR)|" < $(T_MAIN) > $@

clean:
	rm -f $(MAIN) $(CONF)

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
