# $Id: Makefile,v 1.4 2004/04/06 17:18:36 tomas Exp $

include ./config

SRCS= Makefile config


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

clean cgi cgiinstall cgimac fcgi fcgiinstall fcgimac mod modinstall modmac:
	cd libdir; make $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
