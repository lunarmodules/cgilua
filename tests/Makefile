# $Id: Makefile,v 1.2 2004/04/06 17:18:36 tomas Exp $

T= test

include ../config

V= 1.0a
#DIST_DIR=../$(PKG)/$T

SRCS= test.html tcgi1.lua tfcgi1.lua tmod1.lua test_main.html test_main.lua test_main.lp

clean cgi fcgi mod cgimac fcgimac modmac:

cgiinstall fcgiinstall modinstall:

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
