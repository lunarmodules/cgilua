# $Id: Makefile,v 1.13 2004/08/06 16:23:37 tomas Exp $

include ./config

SRCS= Makefile config README


dist:
	mkdir -p $(PKG)
	cp $(SRCS) $(PKG)
	cd luafilesystem; export DIST_DIR=../$(PKG)/luafilesystem; make -e $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
	cd test; make $@
	tar -czf $(TAR_FILE) $(PKG)
	zip -rq $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)

cgi fcgi mod:
	cd luafilesystem; export LIB_EXT="$(LIB_EXT)"; export LIB_OPTION="$(LIB_OPTION)"; export CFLAGS="$(CFLAGS)"; export LIBS="$(LIBS)"; make -e lib
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@

cgiinstall fcgiinstall modinstall:
	cd luafilesystem; export LIB_EXT="$(LIB_EXT)"; export LIB_DIR=$(CGILUA_BINLIB_DIR); export LUA_DIR=$(CGILUA_LIBDIR); make -e install
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@

clean:
	cd luafilesystem; export LIB_EXT="$(LIB_EXT)"; make -e $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
