# Makefile for mkinitcpio

VERSION = 0.7

DIRS = \
	/bin \
	/sbin \
	/etc/bash_completion.d \
	/etc/mkinitcpio.d \
	/lib/initcpio/hooks \
	/lib/initcpio/install \
	/lib/initcpio/udev \
	/usr/share/man/man5

DIST_EXTRA = \
	mkinitcpio.5

all: doc

install: all
	$(foreach dir,${DIRS},install -dm755 ${DESTDIR}${dir};)

	sed -e 's|^CONFIG=.*|CONFIG=/etc/mkinitcpio.conf|' \
	    -e 's|^FUNCTIONS=.*|FUNCTIONS=/lib/initcpio/functions|' \
	    -e 's|^HOOKDIR=.*|HOOKDIR=/lib/initcpio/hooks|' \
	    -e 's|^INSTDIR=.*|INSTDIR=/lib/initcpio/install|' \
	    -e 's|^PRESETDIR=.*|PRESETDIR=/etc/mkinitcpio.d|' \
	    < mkinitcpio > ${DESTDIR}/sbin/mkinitcpio

	sed -e 's|\(^declare FUNCTIONS\)=.*|\1=/lib/initcpio/functions|' \
	    -e 's|%VERSION%|${VERSION}|g' \
	    < lsinitcpio > ${DESTDIR}/bin/lsinitcpio

	chmod 755 ${DESTDIR}/bin/lsinitcpio ${DESTDIR}/sbin/mkinitcpio

	install -m644 mkinitcpio.conf ${DESTDIR}/etc/mkinitcpio.conf
	install -m755 -t ${DESTDIR}/lib/initcpio init
	install -m644 -t ${DESTDIR}/lib/initcpio init_functions functions
	install -m644 01-memdisk.rules ${DESTDIR}/lib/initcpio/udev/01-memdisk.rules

	install -m644 -t ${DESTDIR}/lib/initcpio/hooks hooks/*
	install -m644 -t ${DESTDIR}/lib/initcpio/install install/*
	install -m644 -t ${DESTDIR}/etc/mkinitcpio.d mkinitcpio.d/*

	install -m644 mkinitcpio.5 ${DESTDIR}/usr/share/man/man5/mkinitcpio.5
	install -m644 bash-completion ${DESTDIR}/etc/bash_completion.d/mkinitcpio

doc: mkinitcpio.5
mkinitcpio.5: mkinitcpio.5.txt Makefile
	a2x -d manpage \
		-f manpage \
		-a mansource=mkinitcpio \
		-a manversion=${VERSION} \
		-a manmanual=mkinitcpio mkinitcpio.5.txt

clean:
	${RM} -r build mkinitcpio-${VERSION}
	${RM} mkinitcpio-${VERSION}.tar.gz mkinitcpio.5 mkinitcpio.5.gz

tarball: dist
dist: doc
	git archive --prefix=mkinitcpio-${VERSION}/ -o mkinitcpio-${VERSION}.tar HEAD
	mkdir mkinitcpio-${VERSION}; \
		cp -t mkinitcpio-${VERSION} ${DIST_EXTRA}; \
		tar uf mkinitcpio-${VERSION}.tar mkinitcpio-${VERSION}; \
		${RM} -r mkinitcpio-${VERSION}
	gzip -9 mkinitcpio-${VERSION}.tar

.PHONY: clean dist install tarball
