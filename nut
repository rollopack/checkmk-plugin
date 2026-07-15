#!/bin/bash
# Description: Agent plugin — dump UPS status via NUT (Network UPS Tools)
# Type: agent plugin
# Section: <<<nut>>>

if which upsc > /dev/null 2>&1; then
  echo '<<<nut>>>'
  for ups in $(upsc -l 2>/dev/null); do
    echo "==> $ups <=="
    upsc $ups 2>/dev/null
  done
fi