# $Id: Makefile,v 1.4 2004/04/21 15:12:25 tomas Exp $

T= doc

include ../config

V= 1.0a
#DIST_DIR=../$(PKG)/$T

SRCS= sapi.html cgi-128.gif config.html index.html libraries.html license.html reference.html scripts.html

clean cgi fcgi mod cgimac fcgimac modmac:

cgiinstall fcgiinstall modinstall:
	mkdir -p $(CGILUA_DOC)
	cp $(SRCS) $(CGILUA_DOC)

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
