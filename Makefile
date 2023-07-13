#pass - unix password manager
NAME = pass
VERSION = 0.1
PREFIX ?= /usr/local

all:
	@echo "Only a shell script, try 'make install' instead."

test:
	sh test.sh

dist:
	@echo creating dist tarball
	@mkdir -p ${NAME}-${VERSION}
	@cp -R pass.sh Makefile ${NAME}-${VERSION}
	@tar -cf ${NAME}-${VERSION}.tar ${NAME}-${VERSION}
	@gzip ${NAME}-${VERSION}.tar
	@rm -rf ${NAME}-${VERSION}

install: pass.sh getopts/getopts.sh
	@VERSION="`git describe --first-parent --always`" awk '\
		/^\. / { f=$$2; while (getline < f) print; next; } \
		/^pass_version.*}/ { \
			print "pass_version() { echo " ENVIRON["VERSION"] "; }"; next; \
		} \
		{ print; } \
	' <pass.sh >"${DESTDIR}${PREFIX}/bin/pass"
	@cp git-credential-pass.sh "${DESTDIR}${PREFIX}/bin/git-credential-pass"
	@chmod 755 "${DESTDIR}${PREFIX}/bin/pass"
	@chmod 755 "${DESTDIR}${PREFIX}/bin/git-credential-pass"
	@mkdir -p ${PREFIX}/share/zsh/site-functions
	@cp completion.zsh ${PREFIX}/share/zsh/site-functions/_pass
	@chmod 755 ${PREFIX}/share/zsh/site-functions/_pass

uninstall:
	@rm -f "${DESTDIR}${PREFIX}/bin/pass" \

.PHONY: dist install uninstall test
