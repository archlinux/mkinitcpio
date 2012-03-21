# Makefile for mkinitcpio

VERSION = $(shell if test -f VERSION; then cat VERSION; else git describe | sed 's/-/./g'; fi)

DIRS = \
	/usr/bin \
	/usr/share/bash-completion/completions \
	/etc/mkinitcpio.d \
	/usr/lib/initcpio/hooks \
	/usr/lib/initcpio/install \
	/usr/lib/initcpio/udev \
	/usr/share/man/man8

DIST_EXTRA = \
	mkinitcpio.8

all: doc

install: all
	$(foreach dir,${DIRS},install -dm755 ${DESTDIR}${dir};)

	sed -e 's|^CONFIG=.*|CONFIG=/etc/mkinitcpio.conf|' \
	    -e 's|^FUNCTIONS=.*|FUNCTIONS=/usr/lib/initcpio/functions|' \
	    -e 's|^HOOKDIR=.*|HOOKDIR=({/usr,}/lib/initcpio/hooks)|' \
	    -e 's|^INSTDIR=.*|INSTDIR=({/usr,}/lib/initcpio/install)|' \
	    -e 's|^PRESETDIR=.*|PRESETDIR=/etc/mkinitcpio.d|' \
	    -e 's|%VERSION%|${VERSION}|g' \
	    < mkinitcpio > ${DESTDIR}/usr/bin/mkinitcpio

	sed -e 's|\(^declare FUNCTIONS\)=.*|\1=/usr/lib/initcpio/functions|' \
	    -e 's|%VERSION%|${VERSION}|g' \
	    < lsinitcpio > ${DESTDIR}/usr/bin/lsinitcpio

	chmod 755 ${DESTDIR}/usr/bin/lsinitcpio ${DESTDIR}/usr/bin/mkinitcpio

	install -m644 mkinitcpio.conf ${DESTDIR}/etc/mkinitcpio.conf
	install -m755 -t ${DESTDIR}/usr/lib/initcpio init shutdown
	install -m644 -t ${DESTDIR}/usr/lib/initcpio init_functions functions
	install -m644 01-memdisk.rules ${DESTDIR}/usr/lib/initcpio/udev/01-memdisk.rules

	install -m644 -t ${DESTDIR}/usr/lib/initcpio/hooks hooks/*
	install -m644 -t ${DESTDIR}/usr/lib/initcpio/install install/*
	install -m644 -t ${DESTDIR}/etc/mkinitcpio.d mkinitcpio.d/*

	install -m644 mkinitcpio.8 ${DESTDIR}/usr/share/man/man8/mkinitcpio.8
	install -m644 bash-completion ${DESTDIR}/usr/share/bash-completion/completions/mkinitcpio

doc: mkinitcpio.8
mkinitcpio.8: mkinitcpio.8.txt Makefile
	a2x -d manpage \
		-f manpage \
		-a mansource=mkinitcpio \
		-a manversion=${VERSION} \
		-a manmanual=mkinitcpio mkinitcpio.8.txt

clean:
	${RM} -r build mkinitcpio-${VERSION}
	${RM} mkinitcpio-${VERSION}.tar.gz mkinitcpio.8 mkinitcpio.8.gz

tarball: dist
dist: clean doc
	git archive --prefix=mkinitcpio-${VERSION}/ -o mkinitcpio-${VERSION}.tar HEAD
	mkdir mkinitcpio-${VERSION}; \
		cp -t mkinitcpio-${VERSION} ${DIST_EXTRA}; \
		echo ${VERSION} > mkinitcpio-${VERSION}/VERSION; \
		tar uf mkinitcpio-${VERSION}.tar mkinitcpio-${VERSION}; \
		${RM} -r mkinitcpio-${VERSION}
	gzip -9 mkinitcpio-${VERSION}.tar

version:
	@echo ${VERSION}

.PHONY: clean dist install tarball version
