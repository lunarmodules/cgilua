# $Id: Makefile,v 1.2 2004/03/25 18:58:07 tomas Exp $

include ./config

SRCS= Makefile config


all so dylib install clean cgi cgiinstall cgimac fcgi fcgiinstall fcgimac mod modinstall modmac:
	cd libdir; make $@
	cd launcher; make $@
	cd weblib; make $@
	cd doc; make $@

dist:
	mkdir -p $(PKG)
	cp $(SRCS) $(PKG)
	cd libdir; make $@
	cd launcher; make $@
	cd weblib; make $@
	cd doc; make $@
	cd test; make $@
	tar -czf $(TAR_FILE) $(PKG)
	zip -lrq $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)
