# $Id: Makefile,v 1.1 2003/09/28 23:38:45 tomas Exp $

include ../config

SRCS= cgi-128.gif config.html functions.html index.html scripts.html templates.html upload.html
DIST_DIR= ../$(PKG)/doc

dist: $(SRCS)
	mkdir -p $(DIST_DIR)
	cp Makefile $(SRCS) $(DIST_DIR)
