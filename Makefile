# $Id: Makefile,v 1.9 2004/06/09 18:39:55 tomas Exp $

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
	zip -rq $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)

clean cgi cgiinstall fcgi fcgiinstall mod modinstall:
	cd libfilesystem; make $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
