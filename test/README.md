# Test running

Running one specific test with the current setup:

```bash
$ meson setup build
$ cd build/
$ MESON_TEST=1 bats --verbose-run ../test/cases/mkinitcpio.bats --filter "some test"
```

We need this as `meson` does not allow us to instrument the test runnign with a filter.
