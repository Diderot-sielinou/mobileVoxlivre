#!/usr/bin/env bash
# Échoue si la couverture des lignes de coverage/lcov.info est sous le
# plancher. Le plancher monte avec les fonctionnalités, il ne baisse jamais.
# Limite connue : lcov ne compte que les fichiers chargés par un test.
set -euo pipefail
floor="${1:?usage: coverage_gate.sh <plancher en %>}"
file=coverage/lcov.info
[ -f "$file" ] || { echo "coverage_gate : $file absent (lancer make test)" >&2; exit 1; }
awk -F: -v floor="$floor" '
  /^LF:/ { found += $2 }
  /^LH:/ { hit += $2 }
  END {
    if (found == 0) { print "coverage_gate : aucune ligne mesurée"; exit 1 }
    pct = 100 * hit / found
    printf "Couverture des lignes : %.1f %% (plancher %s %%)\n", pct, floor
    if (pct < floor) exit 1
  }' "$file"
