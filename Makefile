# $Id: Makefile,v 1.31 2005/02/01 16:48:03 tomas Exp $

include ./config

SRCS= Makefile config README
DIST_DIR= $(PKG)


dist: dist_dir
	tar -czf $(TAR_FILE) $(DIST_DIR)
	zip -rq $(ZIP_FILE) $(DIST_DIR)/*
	rm -rf $(DIST_DIR)

dist_dir: luafilesystem $(COMPAT_DIR)
	mkdir -p $(DIST_DIR)
	cp $(SRCS) $(DIST_DIR)
	cd luafilesystem; export DIST_DIR=../$(DIST_DIR)/luafilesystem; make -e dist_dir
	mkdir $(DIST_DIR)/compat; cp $(COMPAT_DIR)/compat* $(DIST_DIR)/compat
	cd launcher; export DIST_DIR="../$(DIST_DIR)/launcher"; make -e dist_dir
	cd clmain; export COMPAT_DIR="../$(COMPAT_DIR)"; export DIST_DIR="../$(DIST_DIR)/clmain"; make -e dist_dir
	cd doc; export DIST_DIR="../$(DIST_DIR)/doc"; make -e dist_dir
	cd test; export DIST_DIR="../$(DIST_DIR)/test"; make -e dist_dir

cgi fcgi mod: $(COMPAT_DIR) luafilesystem
	cd luafilesystem; export COMPAT_DIR="../$(COMPAT_DIR)"; export LUA_INC="$(LUA_INC)"; export LUA_LIBS="$(LUA_LIBS)"; export DLLIB="$(DLLIB)"; export LIB_EXT="$(LIB_EXT)"; export LIB_OPTION="$(LIB_OPTION)"; make -e lib
	cd launcher; export LIB_EXT="$(LIB_EXT)"; make -e $@
	cd clmain; export COMPAT_DIR="../$(COMPAT_DIR)"; make -e $@
	cd doc; make $@

cgiinstall fcgiinstall modinstall: luafilesystem
	cd luafilesystem; export COMPAT_DIR="../$(COMPAT_DIR)"; export LIB_EXT="$(LIB_EXT)"; export LIB_OPTION="$(LIB_OPTION)"; export LIB_DIR="$(LUA_LIBDIR)"; export LUA_DIR=/dev/null; make -e install
	cd launcher; make $@
	cd clmain; export COMPAT_DIR="../$(COMPAT_DIR)"; make -e $@
	cd doc; make $@

clean:
	cd luafilesystem; export LIB_EXT="$(LIB_EXT)"; make -e $@
	cd launcher; make $@
	cd clmain; make $@
	cd doc; make $@

luafilesystem:
	cvs checkout -P luafilesystem

$(COMPAT_DIR):
	cvs checkout -r release_2 compat
