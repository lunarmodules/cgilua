# $Id: Makefile,v 1.7 2004/05/10 07:39:33 tomas Exp $

include ./config

SRCS= Makefile config README


dist:
	mkdir -p $(PKG)
	cp $(SRCS) $(PKG)
	cd libfilesystem; make $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
	cd test; make $@
	tar -czf $(TAR_FILE) $(PKG)
	zip -lrq $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)

clean cgi cgiinstall cgimac fcgi fcgiinstall fcgimac mod modinstall modmac:
	cd libfilesystem; make $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
