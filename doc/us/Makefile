# $Id: Makefile,v 1.5 2004/06/08 12:50:06 tomas Exp $

T= doc

include ../config

V= 1.0a
#DIST_DIR=../$(PKG)/$T

SRCS= sapi.html cgi-128.gif config.html index.html libraries.html license.html reference.html scripts.html

clean cgi fcgi mod:

cgiinstall fcgiinstall modinstall:
	mkdir -p $(CGILUA_DOC)
	cp $(SRCS) $(CGILUA_DOC)

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
