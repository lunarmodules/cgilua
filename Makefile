# $Id: Makefile,v 1.5 2004/04/21 15:12:25 tomas Exp $

include ./config

SRCS= Makefile config README


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
