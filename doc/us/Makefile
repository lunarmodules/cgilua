# $Id: Makefile,v 1.7 2005/02/11 14:32:33 tomas Exp $

T= doc

include ../config


SRCS= sapi.html cgi-128.gif config.html index.html libraries.html license.html reference.html scripts.html

clean cgi fcgi mod:

cgiinstall fcgiinstall modinstall:
	mkdir -p $(CGILUA_DOC)
	cp $(SRCS) $(CGILUA_DOC)

dist dist_dir:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
