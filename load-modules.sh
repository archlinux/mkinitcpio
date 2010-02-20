#! /bin/sh
# Implement blacklisting for udev-loaded modules
#   Includes module checking
# - Aaron Griffin, Tobias Powalowski & Thomas Bächler for Arch Linux
[ $# -ne 1 ] && exit 1

MODPROBE="/sbin/modprobe"
RESOLVEALIAS="${MODPROBE} --resolve-alias"
USEBLACKLIST="--use-blacklist"
SED="/bin/sed"

if [ -f /proc/cmdline ]; then
  for cmd in $(cat /proc/cmdline); do
    case $cmd in
      disablemodules=*) eval $cmd ;;
      load_modules=off) exit ;;
    esac
  done
  #parse cmdline entries of the form "disablemodules=x,y,z"
  if [ -n "${disablemodules}" ]; then
    BLACKLIST="$(echo "${disablemodules}" | ${SED} 's|,| |g')"
  fi
fi

# sanitize the module names
BLACKLIST="$(echo "${BLACKLIST}" | ${SED} 's|-|_|g')"

if [ -n "${BLACKLIST}" ] ; then
  # Try to find all modules for the alias
  mods="$($RESOLVEALIAS $1)"
  # If no modules could be found, try if the alias name is a module name
  # In that case, omit the --use-blacklist parameter to imitate normal modprobe behaviour
  [ -z "${mods}" ] && $MODPROBE -qni $1 && mods="$1" && USEBLACKLIST=""
  [ -z "${mods}" ] && exit
  for mod in ${mods}; do
    # Find the module and all its dependencies
    deps="$($MODPROBE -i --show-depends ${mod})"
    [ $? -ne 0 ] && continue

    #sanitize the module names
    deps="$(echo "$deps" | ${SED} \
            -e "s#^insmod /lib.*/\(.*\)\.ko.*#\1#g" \
            -e 's|-|_|g')"
    # If the module or any of its dependencies is blacklisted, don't load it
    for dep in $deps; do
      for blackmod in ${BLACKLIST}; do
        [ "${blackmod}" = "${dep}" ] && continue 3
      done
    done
    $MODPROBE $USEBLACKLIST ${mod}
  done
else
  $MODPROBE $USEBLACKLIST $1
fi

# vim: set et ts=4:
