# $Id: Makefile,v 1.2 2004/03/25 18:54:57 tomas Exp $

T= doc

include ../config

V= 1.0a
#DIST_DIR=../$(PKG)/$T

SRCS= basic_api.html cgi-128.gif config.html index.html libraries.html reference.html scripts.html

all clean so dylib cgi fcgi mod cgimac fcgimac modmac:

install cgiinstall fcgiinstall modinstall:
	mkdir -p $(CGILUA_DOC)
	cp $(SRCS) $(CGILUA_DOC)

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
