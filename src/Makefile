# $Id: Makefile,v 1.7 2004/05/26 17:34:04 tomas Exp $

T= clmain

include ../config

#DIST_DIR=../$(PKG)/$T

LIBS= cgilua.lua cookies.lua post.lua prep.lua readuntil.lua urlcode.lua venv.lua
CONF= cgilua.conf
T_CONF= t_cgilua.conf
MAIN= main.lua
T_MAIN= t_main.lua
LUAS= $(MAIN) $(CONF) $(LIBS)
SRCS= $(T_MAIN) $(T_CONF) cgilua.lua cookies.lua post.lua prep.lua readuntil.lua urlcode.lua venv.lua

cgi fcgi mod cgimac fcgimac modmac: $(LUAS)

cgiinstall fcgiinstall modinstall: $(LUAS)
	mkdir -p $(CGILUA_DIR)
	cp $(MAIN) $(CGILUA_DIR)
	mkdir -p $(CGILUA_CONFDIR)
	cp $(CONF) $(CGILUA_CONF)
	mkdir -p $(CGILUA_LIBDIR)
	cp $(LIBS) $(CGILUA_LIBDIR)
	mkdir -p $(CGILUA_USRLIBDIR)

$(CONF): $(T_CONF)
	sed -e "s|CGILUA_DIR|$(CGILUA_DIR)|" < $(T_CONF) > $@

$(MAIN): $(T_MAIN)
	sed -e "s|CGILUA_DIR|$(CGILUA_DIR)|" < $(T_MAIN) > $@

clean:
	rm -f $(MAIN) $(CONF)

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
