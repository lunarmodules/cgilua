# $Id: Makefile,v 1.4 2004/04/09 09:19:49 tomas Exp $

T= weblib

include ../config

#DIST_DIR=../$(PKG)/$T

LIBS= cgilua.lua post.lua prep.lua readuntil.lua urlcode.lua sandbox.lua
USRLIBS= cookies.lua
CONF= cgilua.conf
T_CONF= t_cgilua.conf
MAIN= main.lua
T_MAIN= t_main.lua
LUAS= $(MAIN) $(CONF) $(LIBS)
SRCS= $(T_MAIN) $(T_CONF) $(USRLIBS) cgilua.lua post.lua prep.lua readuntil.lua urlcode.lua sandbox.lua

cgi fcgi mod cgimac fcgimac modmac: $(LUAS)

cgiinstall fcgiinstall modinstall: $(LUAS)
	mkdir -p $(CGILUA_DIR)
	cp $(MAIN) $(CGILUA_DIR)
	mkdir -p $(CGILUA_CONFDIR)
	cp $(CONF) $(CGILUA_CONF)
	mkdir -p $(CGILUA_LIBDIR)
	cp $(LIBS) $(CGILUA_LIBDIR)
	mkdir -p $(CGILUA_USRLIBDIR)
	cp $(USRLIBS) $(CGILUA_USRLIBDIR)

$(CONF): $(T_CONF)
	sed -e "s|CGILUA_DIR|$(CGILUA_DIR)|" < $(T_CONF) > $@

$(MAIN): $(T_MAIN)
	sed -e "s|CGILUA_DIR|$(CGILUA_DIR)|" < $(T_MAIN) > $@

clean:
	rm -f $(MAIN) $(CONF)

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
