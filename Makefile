# $Id: Makefile,v 1.1 2003/09/28 23:38:44 tomas Exp $

include config

TAR_FILE= $(PKG).tar.gz
ZIP_FILE= $(PKG).zip


all:
	cd src; make all

install: cgi-bin/map.lua cgi-bin/cgilua
	cp -f cgi-bin/cgilua $(CGI_DIR)
	# avoid overwritting `map.lua'
	cp -i cgi-bin/map.lua $(CGI_DIR)
	mkdir -p $(CGILUA_DIR)
	cp -f clmain/*lua $(CGILUA_DIR)
	mkdir -p $(CGILUA_LIBDIR)
	cp -f lib/* $(CGILUA_LIBDIR)

cgi-bin/map.lua:

cgi-bin/cgilua:
	cd src; make all

clean:
	cd src; make clean
	rm -f $(TAR_FILE) $(ZIP_FILE)

remove:
	# remove `map.lua' with confirmation
	rm -i $(CGI_DIR)/map.lua
	rm -f $(CGI_DIR)/cgilua
	rm -f $(CGILUA_LIBDIR)/*
	rmdir $(CGILUA_LIBDIR)
	rm -f $(CGILUA_DIR)/*
	rmdir $(CGILUA_DIR)

dist:
	mkdir -p $(PKG)
	cp config Makefile $(PKG)
	cd src; make dist
	cd cgi-bin; make dist
	cd clmain; make dist
	cd doc; make dist
	cd lib; make dist
	tar -czf $(TAR_FILE) $(PKG)
	zip -lqr9 $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)
