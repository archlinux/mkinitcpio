# Makefile for mkinitcpio
# SPDX-License-Identifier: GPL-2.0-only

VERSION = $(shell ./tools/dist.sh get-version)

all:
	@printf "mkinitcpio now requires meson to build, install, and run tests."
prepare: all
	@echo " Use:"
	@echo "	meson setup build"
install: prepare
	@echo "	meson install -C build"
check: prepare
	@echo "	meson test -C build --suite bats"
shellcheck: prepare
	@echo "	meson test -C build --suite shellcheck"
coverage: prepare
	@echo "	meson test -C build --suite coverage"

clean:
	$(RM) -r build mkinitcpio-$(VERSION).tar.xz.sig mkinitcpio-$(VERSION).tar.xz

dist: mkinitcpio-$(VERSION).tar.xz
mkinitcpio-$(VERSION).tar.xz:
	meson setup build $(MESON_ARGS)
	meson dist -C build
	cp build/meson-dist/$@ $@

mkinitcpio-$(VERSION).tar.xz.sig: mkinitcpio-$(VERSION).tar.xz
	gpg --detach-sign $<

upload: mkinitcpio-$(VERSION).tar.xz mkinitcpio-$(VERSION).tar.xz.sig
	scp $^ repos.archlinux.org:/srv/ftp/other/mkinitcpio

.PHONY: check clean coverage dist install shellcheck prepare upload
