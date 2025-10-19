#!/bin/bash
# Will set all files in a directory to lowercase or capital letters
# The toggle works... the first file first character is checked and from there the toggle is set
toggle=0 #0=disabled, 1=lower, 2=higher
if pushd "${1}" 2>/dev/null; then
  for f in *; do
    if [[ -f "$f" && $toggle -eq 0 ]]; then
      [[ "${f:0:1}" == [A-Z] ]] && toggle=1 || toggle=2
    fi
    [[ -f "$f" && $toggle -eq 1 ]] && mv -v -- "$f" "${f,,}"
    [[ -f "$f" && $toggle -eq 2 ]] && mv -v -- "$f" "${f^^}"
  done
    popd >/dev/null
  else
    echo "couldn't go to dir: '$1'"; exit 1
fi
