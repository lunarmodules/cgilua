# $Id: Makefile,v 1.17 2004/09/29 18:21:41 tomas Exp $

include ./config

SRCS= Makefile config README


dist: luafilesystem
	mkdir -p $(PKG)
	cp $(SRCS) $(PKG)
	cd luafilesystem; export DIST_DIR=../$(PKG)/luafilesystem; make -e dist_dir
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@
	cd test; make $@
	tar -czf $(TAR_FILE) $(PKG)
	zip -rq $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)

cgi fcgi mod: luafilesystem
	cd luafilesystem; export LIB_EXT="$(LIB_EXT)"; export LIB_OPTION="$(LIB_OPTION)"; export CFLAGS="$(CFLAGS)"; export LIBS="$(LIBS)"; make -e lib
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@

cgiinstall fcgiinstall modinstall: luafilesystem
	cd luafilesystem; export LIB_EXT="$(LIB_EXT)"; export LIB_DIR="$(LUA_LIBDIR)"; export LUA_DIR=/dev/null; make -e install
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@

clean:
	cd luafilesystem; export LIB_EXT="$(LIB_EXT)"; make -e $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@

luafilesystem:
	cvs -d poison:/usr/local/cvsroot checkout luafilesystem
