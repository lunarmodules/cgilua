# $Id: Makefile,v 1.3 2004/04/20 14:04:00 tomas Exp $

T= test

include ../config

V= 1.0a
#DIST_DIR=../$(PKG)/$T

SRCS= test_main.html test_main.lua test_main.lp test_cookies.lua test_cookies.lp

clean cgi fcgi mod cgimac fcgimac modmac:

cgiinstall fcgiinstall modinstall:

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
