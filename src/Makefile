# $Id: Makefile,v 1.1 2003/09/28 23:38:44 tomas Exp $

include ../config

SRCS= cgilua.lua main.lua prep.lua readuntil.lua
DIST_DIR= ../$(PKG)/clmain

dist: $(SRCS)
	mkdir -p $(DIST_DIR)
	cp Makefile $(SRCS) $(DIST_DIR)
