# $Id: Makefile,v 1.8 2004/06/08 12:50:06 tomas Exp $

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

clean cgi cgiinstall fcgi fcgiinstall mod modinstall:
	cd libfilesystem; make $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
