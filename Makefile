# Makefile for mkinitcpio
# SPDX-License-Identifier: GPL-2.0-only

VERSION = $(shell if test -f VERSION; then cat VERSION; else git describe | sed 's/-/./g;s/^v//;'; fi)
JOBS ?= $(shell nproc)

DIRS = \
	/usr/bin \
	/usr/share/bash-completion/completions \
	/usr/share/zsh/site-functions \
	/etc/mkinitcpio.d \
	/etc/mkinitcpio.conf.d \
	/etc/initcpio/hooks \
	/etc/initcpio/install \
	/etc/initcpio/post \
	/usr/lib/initcpio/hooks \
	/usr/lib/initcpio/install \
	/usr/lib/initcpio/post \
	/usr/lib/initcpio/udev \
	/usr/lib/kernel/install.d \
	/usr/share/man/man8 \
	/usr/share/man/man5 \
	/usr/share/man/man1 \
	/usr/share/mkinitcpio \
	/usr/lib/tmpfiles.d \
	/usr/share/libalpm/hooks \
	/usr/share/libalpm/scripts

SHUTDOWN_DIRS = \
	/usr/lib/systemd/system/poweroff.target.wants \
	/usr/lib/systemd/system/halt.target.wants \
	/usr/lib/systemd/system/reboot.target.wants \
	/usr/lib/systemd/system/kexec.target.wants

ALL_SCRIPTS=$(shell grep -rIlE '^#! */.+[ /](bash|ash|sh|bats)' --exclude-dir=".git" ./)

all: doc

MANPAGES = \
	man/mkinitcpio.8 \
	man/mkinitcpio.conf.5 \
	man/lsinitcpio.1

prepare:
	install -dm755 $(addprefix $(DESTDIR),$(DIRS)) $(addprefix $(DESTDIR),$(SHUTDOWN_DIRS))

	sed -e 's|\(^_f_config\)=.*|\1=/etc/mkinitcpio.conf|' \
	    -e 's|\(^_f_functions\)=.*|\1=/usr/lib/initcpio/functions|' \
	    -e 's|\(^_d_hooks\)=.*|\1=/etc/initcpio/hooks:/usr/lib/initcpio/hooks|' \
	    -e 's|\(^_d_install\)=.*|\1=/etc/initcpio/install:/usr/lib/initcpio/install|' \
	    -e 's|\(^_d_post\)=.*|\1=/etc/initcpio/post:/usr/lib/initcpio/post|' \
	    -e 's|\(^_d_presets\)=.*|\1=/etc/mkinitcpio.d|' \
	    -e 's|\(^_d_config\)=.*|\1=/etc/mkinitcpio.conf.d|' \
	    -e 's|%VERSION%|$(VERSION)|g' \
	    < mkinitcpio > $(DESTDIR)/usr/bin/mkinitcpio

	sed -e 's|\(^_f_functions\)=.*|\1=/usr/lib/initcpio/functions|' \
	    -e 's|%VERSION%|$(VERSION)|g' \
	    < lsinitcpio > $(DESTDIR)/usr/bin/lsinitcpio

install-generator: all prepare
	chmod 755 $(DESTDIR)/usr/bin/lsinitcpio $(DESTDIR)/usr/bin/mkinitcpio

	install -m644 mkinitcpio.conf $(DESTDIR)/etc/mkinitcpio.conf
	install -m755 -t $(DESTDIR)/usr/lib/initcpio init shutdown
	install -m644 -t $(DESTDIR)/usr/lib/initcpio init_functions functions
	install -m644 udev/01-memdisk.rules $(DESTDIR)/usr/lib/initcpio/udev/01-memdisk.rules

	cp -at $(DESTDIR)/usr/lib/initcpio hooks install
	install -m644 -t $(DESTDIR)/usr/share/mkinitcpio mkinitcpio.d/*

	install -m644 systemd/mkinitcpio-generate-shutdown-ramfs.service \
		$(DESTDIR)/usr/lib/systemd/system/mkinitcpio-generate-shutdown-ramfs.service
	for target in $(addprefix $(DESTDIR),$(SHUTDOWN_DIRS)); do \
		ln -s ../mkinitcpio-generate-shutdown-ramfs.service -t $$target || exit; \
	done
	install -m644 tmpfiles/mkinitcpio.conf $(DESTDIR)/usr/lib/tmpfiles.d/mkinitcpio.conf

	install -m755 kernel-install/50-mkinitcpio.install $(DESTDIR)/usr/lib/kernel/install.d/50-mkinitcpio.install

	install -m644 man/mkinitcpio.8 $(DESTDIR)/usr/share/man/man8/mkinitcpio.8
	install -m644 man/mkinitcpio.conf.5 $(DESTDIR)/usr/share/man/man5/mkinitcpio.conf.5
	install -m644 man/lsinitcpio.1 $(DESTDIR)/usr/share/man/man1/lsinitcpio.1
	install -m644 shell/bash-completion $(DESTDIR)/usr/share/bash-completion/completions/mkinitcpio
	ln -s mkinitcpio $(DESTDIR)/usr/share/bash-completion/completions/lsinitcpio
	install -m644 shell/zsh-completion $(DESTDIR)/usr/share/zsh/site-functions/_mkinitcpio

install-hooks: prepare
	install -m644 libalpm/hooks/90-mkinitcpio-install.hook $(DESTDIR)/usr/share/libalpm/hooks/90-mkinitcpio-install.hook
	install -m644 libalpm/hooks/60-mkinitcpio-remove.hook $(DESTDIR)/usr/share/libalpm/hooks/60-mkinitcpio-remove.hook
	install -m755 libalpm/scripts/mkinitcpio $(DESTDIR)/usr/share/libalpm/scripts/mkinitcpio

install: install-generator install-hooks

doc: $(MANPAGES)
man/%: man/%.adoc Makefile
ifeq ($(shell command -v asciidoctor 2>/dev/null),)
	a2x -f manpage -a manversion="mkinitcpio $(VERSION)" $<
else
	asciidoctor -b manpage -a manversion="mkinitcpio $(VERSION)" $<
endif

check:
	LC_ALL=C.UTF-8 bats --jobs $(JOBS) $(BATS_ARGS) test/cases/


integration:
	bats -r $(BATS_ARGS) test/integration/

coverage:
	kcov \
		--include-path=$(CURDIR) \
		--exclude-path=$(CURDIR)/test \
		$(CURDIR)/coverage \
		bats $(BATS_ARGS) test/cases/

shellcheck:
	shellcheck -W 99 --color $(ALL_SCRIPTS)

clean:
	$(RM) mkinitcpio-$(VERSION).tar.xz.sig mkinitcpio-$(VERSION).tar.xz $(MANPAGES)

dist: doc mkinitcpio-$(VERSION).tar.xz
mkinitcpio-$(VERSION).tar.xz:
	echo $(VERSION) > VERSION
	git archive --format=tar --prefix=mkinitcpio-$(VERSION)/ -o mkinitcpio-$(VERSION).tar HEAD
	bsdtar -rf mkinitcpio-$(VERSION).tar -s ,^,mkinitcpio-$(VERSION)/, $(MANPAGES) VERSION
	xz -z -9e mkinitcpio-$(VERSION).tar
	$(RM) VERSION

mkinitcpio-$(VERSION).tar.xz.sig: mkinitcpio-$(VERSION).tar.xz
	gpg --detach-sign $<

upload: mkinitcpio-$(VERSION).tar.xz mkinitcpio-$(VERSION).tar.xz.sig
	scp $^ repos.archlinux.org:/srv/ftp/other/mkinitcpio

version:
	@echo $(VERSION)

.PHONY: check clean coverage dist install install-generator install-hooks shellcheck tarball version prepare
