#!/bin/bash
#
# Build automation.
#
# Usage:
#   ./build.sh <function name>
#
# Important targets are:
#   doc: build docs with Markdown
#   fastrand: build Python extension module to speed up the client simulation

set -o nounset
set -o pipefail
set -o errexit

log() {
  echo 1>&2 "$@"
}

die() {
  log "FATAL: $@"
  exit 1
}

run-markdown() {
  which markdown >/dev/null || die "Markdown not installed"

  # Markdown is output unstyled; make it a little more readable.
  cat <<EOF
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="UTF-8">
      <style type="text/css">
        code { color: green; }
      </style>
      <!-- INSERT LATCH JS -->
    </head>
    <body style="margin: 0 auto; width: 40em; text-align: left;">
      <!-- INSERT LATCH HTML -->
EOF

  markdown "$@"

  cat <<EOF
    </body>
  </html>
EOF
}

run-dot() {
  local in=$1
  local out=$2

  local msg="dot not found (perhaps 'sudo apt-get install graphviz')"
  which dot >/dev/null || die "$msg"

  log "Running dot"
  dot -Tpng -o $out $in
}

# Scan for TODOs.  Does this belong somewhere else?
todo() {
  find . -name \*.py -o -name \*.R -o -name \*.sh -o -name \*.md \
    | xargs --verbose -- grep -w TODO
}

#
# Targets: build "doc" or "fastrand"
#

# Build dependencies: markdown tool.
doc() {
  mkdir -p _tmp _tmp/doc

  # For now, just one file.
  # TODO: generated docs
  run-markdown <README.md >_tmp/README.html
  run-markdown <doc/tutorial.md >_tmp/doc/tutorial.html

  run-dot doc/tools.dot _tmp/doc/tools.png

  log 'Wrote docs to _tmp'
}

# Build dependencies: Python development headers.  Most systems should have
# this.  On Ubuntu/Debian, the 'python-dev' package contains headers.
fastrand() {
  pushd client/python >/dev/null
  python setup.py build
  # So we can 'import _fastrand' without installing
  ln -s --force build/*/_fastrand.so .
  ./fastrand_test.py

  log 'fastrand built and tests PASSED'
  popd >/dev/null
}

"$@"
