#pass - unix password manager
NAME = pass
VERSION = 0.1
PREFIX ?= /usr/local

all:
	@echo "Only a shell script, try 'make install' instead."

dist:
	@echo creating dist tarball
	@mkdir -p ${NAME}-${VERSION}
	@cp -R pass.sh Makefile ${NAME}-${VERSION}
	@tar -cf ${NAME}-${VERSION}.tar ${NAME}-${VERSION}
	@gzip ${NAME}-${VERSION}.tar
	@rm -rf ${NAME}-${VERSION}

install: pass.sh
	@cp -f pass.sh "${DESTDIR}${PREFIX}/bin/pass"
	@chmod 755 "${DESTDIR}${PREFIX}/bin/pass"

uninstall:
	@rm -f "${DESTDIR}${PREFIX}/bin/pass" \

.PHONY: dist install uninstall
