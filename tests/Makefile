# $Id: Makefile,v 1.1 2004/03/25 19:31:05 tomas Exp $

T= test

include ../config

V= 1.0a
#DIST_DIR=../$(PKG)/$T

SRCS= test.html tcgi1.lua tfcgi1.lua tmod1.lua test_main.html test_main.lua test_main.lp

all clean so dylib cgi fcgi mod cgimac fcgimac modmac:

install cgiinstall fcgiinstall modinstall:

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
