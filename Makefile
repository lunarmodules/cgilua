# $Id: Makefile,v 1.3 2004/03/25 19:03:42 tomas Exp $

include ./config

SRCS= Makefile config


all so dylib install clean cgi cgiinstall cgimac fcgi fcgiinstall fcgimac mod modinstall modmac:
	cd libdir; make $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@

dist:
	mkdir -p $(PKG)
	cp $(SRCS) $(PKG)
	cd libdir; make $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
	cd test; make $@
	tar -czf $(TAR_FILE) $(PKG)
	zip -lrq $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)
