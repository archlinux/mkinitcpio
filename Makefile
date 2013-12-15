# Makefile for mkinitcpio

VERSION = $(shell if test -f VERSION; then cat VERSION; else git describe | sed 's/-/./g;s/^v//;'; fi)

DIRS = \
	/usr/bin \
	/usr/share/bash-completion/completions \
	/usr/share/zsh/site-functions \
	/etc/mkinitcpio.d \
	/etc/initcpio/hooks \
	/etc/initcpio/install \
	/usr/lib/initcpio/hooks \
	/usr/lib/initcpio/install \
	/usr/lib/initcpio/udev \
	/usr/lib/kernel/install.d \
	/usr/share/man/man8 \
	/usr/share/man/man5 \
	/usr/share/man/man1 \
	/usr/share/mkinitcpio \
	/usr/lib/systemd/system/shutdown.target.wants \
	/usr/lib/tmpfiles.d

all: doc

MANPAGES = \
	man/mkinitcpio.8 \
	man/mkinitcpio.conf.5 \
	man/lsinitcpio.1

install: all
	mkdir -p $(DESTDIR)
	$(foreach dir,$(DIRS),install -dm755 $(DESTDIR)$(dir);)

	sed -e 's|^_f_config=.*|_f_config=/etc/mkinitcpio.conf|' \
	    -e 's|^_f_functions=.*|_f_functions=/usr/lib/initcpio/functions|' \
	    -e 's|^_d_hooks=.*|_d_hooks=/etc/initcpio/hooks:/usr/lib/initcpio/hooks|' \
	    -e 's|^_d_install=.*|_d_install=/etc/initcpio/install:/usr/lib/initcpio/install|' \
	    -e 's|^_d_presets=.*|_d_presets=/etc/mkinitcpio.d|' \
	    -e 's|%VERSION%|$(VERSION)|g' \
	    < mkinitcpio > $(DESTDIR)/usr/bin/mkinitcpio

	sed -e 's|\(^_f_functions\)=.*|\1=/usr/lib/initcpio/functions|' \
	    -e 's|%VERSION%|$(VERSION)|g' \
	    < lsinitcpio > $(DESTDIR)/usr/bin/lsinitcpio

	chmod 755 $(DESTDIR)/usr/bin/lsinitcpio $(DESTDIR)/usr/bin/mkinitcpio

	install -m644 mkinitcpio.conf $(DESTDIR)/etc/mkinitcpio.conf
	install -m755 -t $(DESTDIR)/usr/lib/initcpio init shutdown
	install -m644 -t $(DESTDIR)/usr/lib/initcpio init_functions functions
	install -m644 udev/01-memdisk.rules $(DESTDIR)/usr/lib/initcpio/udev/01-memdisk.rules

	cp -at $(DESTDIR)/usr/lib/initcpio hooks install
	install -m644 -t $(DESTDIR)/usr/share/mkinitcpio mkinitcpio.d/*
	install -m644 systemd/mkinitcpio-generate-shutdown-ramfs.service \
			$(DESTDIR)/usr/lib/systemd/system/mkinitcpio-generate-shutdown-ramfs.service
	ln -s ../mkinitcpio-generate-shutdown-ramfs.service \
			$(DESTDIR)/usr/lib/systemd/system/shutdown.target.wants/mkinitcpio-generate-shutdown-ramfs.service
	install -m644 tmpfiles/mkinitcpio.conf $(DESTDIR)/usr/lib/tmpfiles.d/mkinitcpio.conf

	install -m755 50-mkinitcpio.install $(DESTDIR)/usr/lib/kernel/install.d/50-mkinitcpio.install

	install -m644 man/mkinitcpio.8 $(DESTDIR)/usr/share/man/man8/mkinitcpio.8
	install -m644 man/mkinitcpio.conf.5 $(DESTDIR)/usr/share/man/man5/mkinitcpio.conf.5
	install -m644 man/lsinitcpio.1 $(DESTDIR)/usr/share/man/man1/lsinitcpio.1
	install -m644 shell/bash-completion $(DESTDIR)/usr/share/bash-completion/completions/mkinitcpio
	ln -s mkinitcpio $(DESTDIR)/usr/share/bash-completion/completions/lsinitcpio
	install -m644 shell/zsh-completion $(DESTDIR)/usr/share/zsh/site-functions/_mkinitcpio

doc: $(MANPAGES)
man/%: man/%.txt Makefile
	a2x -d manpage \
		-f manpage \
		-a manversion=$(VERSION) \
		-a manmanual="mkinitcpio manual" $<

clean:
	$(RM) mkinitcpio-${VERSION}.tar.gz $(MANPAGES)

dist: doc
	echo $(VERSION) > VERSION
	git archive --format=tar --prefix=mkinitcpio-$(VERSION)/ -o mkinitcpio-$(VERSION).tar HEAD
	bsdtar -rf mkinitcpio-$(VERSION).tar -s ,^,mkinitcpio-$(VERSION)/, $(MANPAGES) VERSION
	gzip -9 mkinitcpio-$(VERSION).tar
	$(RM) VERSION

version:
	@echo $(VERSION)

.PHONY: clean dist install tarball version
