# $Id: Makefile,v 1.6 2004/05/09 21:48:04 tomas Exp $

include ./config

SRCS= Makefile config README


dist:
	mkdir -p $(PKG)
	cp $(SRCS) $(PKG)
	cd libfs; make $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
	cd test; make $@
	tar -czf $(TAR_FILE) $(PKG)
	zip -lrq $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)

clean cgi cgiinstall cgimac fcgi fcgiinstall fcgimac mod modinstall modmac:
	cd libfs; make $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
