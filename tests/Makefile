# $Id: Makefile,v 1.4 2004/06/08 12:50:06 tomas Exp $

T= test

include ../config

V= 1.0a
#DIST_DIR=../$(PKG)/$T

SRCS= test_main.html test_main.lua test_main.lp test_cookies.lua test_cookies.lp

clean cgi fcgi mod:

cgiinstall fcgiinstall modinstall:

dist:
	mkdir -p $(DIST_DIR)
	cp $(SRCS) Makefile $(DIST_DIR)
