# $Id: Makefile,v 1.2 2004/03/25 19:01:39 tomas Exp $

T= weblib

include ../config

#DIST_DIR=../$(PKG)/$T

LIBS= cgilua.lua post.lua prep.lua readuntil.lua urlcode.lua
CONF= cgilua.conf
T_CONF= t_cgilua.conf
MAIN= main.lua
T_MAIN= t_main.lua
LUAS= $(MAIN) $(CONF) $(LIBS)
SRCS= $(T_MAIN) $(T_CONF) cgilua.lua post.lua prep.lua readuntil.lua urlcode.lua

all so dylib cgi fcgi mod cgimac fcgimac modmac: $(LUAS)

install cgiinstall fcgiinstall modinstall: $(LUAS)
	mkdir -p $(CGILUA_DIR)
	cp $(MAIN) $(CGILUA_DIR)
	mkdir -p $(CGILUA_CONFDIR)
	cp $(CONF) $(CGILUA_CONF)
	mkdir -p $(CGILUA_LIBDIR)
	cp $(LIBS) $(CGILUA_LIBDIR)
	mkdir -p $(CGILUA_USRLIBDIR)

$(CONF): $(T_CONF)
	sed -e "s|CGILUA_USRLIBDIR|$(CGILUA_USRLIBDIR)|" < $(T_CONF) > $@

$(MAIN): $(T_MAIN)
	sed -e "s|CGILUA_LIBDIR|$(CGILUA_LIBDIR)|" -e "s|CGILUA_CONF|$(CGILUA_CONF)|" < $(T_MAIN) > $@

clean:
	rm -f $(MAIN) $(CONF)

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
