# $Id: Makefile,v 1.20 2004/10/29 15:36:30 tomas Exp $

include ./config

SRCS= Makefile config README


dist: luafilesystem compat
	mkdir -p $(PKG)
	cp $(SRCS) $(PKG)
	cd luafilesystem; export DIST_DIR=../$(PKG)/luafilesystem; make -e dist_dir
	cd compat; export DIST_DIR=../$(PKG)/compat; make -e dist_dir
	cd launcher; make $@
	cd clmain; export COMPAT_DIR="../$(COMPAT_DIR)"; make -e $@
	cd doc; make $@
	cd test; make $@
	tar -czf $(TAR_FILE) $(PKG)
	zip -rq $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)

cgi fcgi mod: luafilesystem
	cd luafilesystem; export COMPAT_DIR="../$(COMPAT_DIR)"; export LIB_EXT="$(LIB_EXT)"; export LIB_OPTION="$(LIB_OPTION)"; export LIBS="$(LIBS)"; make -e lib
	cd launcher; make $@
	cd clmain; export COMPAT_DIR="../$(COMPAT_DIR)"; make -e $@
	cd doc; make $@

cgiinstall fcgiinstall modinstall: luafilesystem
	cd luafilesystem; export COMPAT_DIR="../$(COMPAT_DIR)"; export LIB_EXT="$(LIB_EXT)"; export LIB_DIR="$(LUA_LIBDIR)"; export LUA_DIR=/dev/null; make -e install
	cd launcher; make $@
	cd clmain; export COMPAT_DIR="../$(COMPAT_DIR)"; make -e $@
	cd doc; make $@

clean:
	cd luafilesystem; export LIB_EXT="$(LIB_EXT)"; make -e $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@

luafilesystem: compat
	cvs checkout luafilesystem

compat:
	cvs checkout compat
