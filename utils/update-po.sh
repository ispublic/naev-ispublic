#!/bin/bash

# ============================= Enter source root =============================
if [ -n "$1" ]; then
   cd "$1"
elif [ -n "$MESON_SOURCE_ROOT" ]; then
   cd "$MESON_SOURCE_ROOT"
fi

if [[ ! -f naev.6 ]]; then
   echo "Please run from the source root dir, or pass it as an argument." >&2
   exit -1
fi

# ============================== Helper commands ==============================
# find_files <dir> <suffix>
if [ -d .git ]; then
   find_files() { git ls-files -- "$1/**.$2"; }
else
   find_files() {
      find dat -name "*.xml"
      (find dat -name "*.lua"; find src -name "*.[ch]")
   }
fi
# And some pipeline commands:
filter_skipped() { egrep -v '/((space|ship)_polygon)/.*\.xml'; }
deterministic_sort() { LC_ALL=C sort; }

# =================================== Main ===================================

# Prepare POTFILES.in (which lists all files with translatable text).
# We also have plaintext files, whose lines should all be translatable strings.
# We collect these strings into a .pot file, and let xgettext handle the rest.
# The text strings must come first, or else gettext "remembers" its most recent
# language detection and gives them unwanted "c-format" or "lua-format" tags.

po/credits_pot.py \
   dat/intro \
   dat/AUTHORS \
   "$(find_files artwork/gfx/loading txt)" \
   > po/credits.pot

(
   echo po/credits.pot
   find_files dat xml | deterministic_sort
   ( find_files dat lua; find_files src "[ch]") | deterministic_sort
) | filter_skipped > po/POTFILES.in

if [ "$2" = "--pre-commit" ]; then
   # The "pre-commit" package requires hooks to fail if they touch any files.
   git diff --exit-code po/POTFILES.in && exit 0
   echo Fixing po/POTFILES.in
fi
