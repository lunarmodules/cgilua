# $Id: Makefile,v 1.10 2004/07/19 19:30:20 tomas Exp $

include ./config

SRCS= Makefile config README


dist:
	mkdir -p $(PKG)
	cp $(SRCS) $(PKG)
	cd luafilesystem; make -e $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
	cd test; make $@
	tar -czf $(TAR_FILE) $(PKG)
	zip -rq $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)

cgi fcgi mod:
	cd luafilesystem; make -e lib
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@

cgiinstall fcgiinstall modinstall:
	cd luafilesystem; export LUA_DIR=$(CGILUA_LIBDIR); make -e install
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@

clean:
	cd luafilesystem; make -e $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
