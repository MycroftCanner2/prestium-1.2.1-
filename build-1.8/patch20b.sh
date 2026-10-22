#!/bin/bash
# v20b: The Lounge must never contact the Internet itself: disable the GitHub changelog/update
# check (its blocked request crashed the server: uncaught p-cancelable error) and the
# "npm/yarn outdated" package check. Both are replaced by no-ops.
set -e
T=/workspace/work/prestium/v19/rootfs/opt/thelounge/node_modules/thelounge/dist/server/plugins
sudo python3 - $T/changelog.js $T/packages/index.js <<'PY'
import sys
c,p=sys.argv[1],sys.argv[2]
s=open(c).read()
if 'Prestium' not in s:
    a='async function fetch() {\n'
    assert s.count(a)==1
    s=s.replace(a,a+'    // Prestium: no external fetches (never contacts api.github.com)\n    return versions;\n')
    b='function checkForUpdates(manager) {\n'
    assert s.count(b)==1
    s=s.replace(b,b+'    // Prestium: update check disabled (local-only, offline)\n    return;\n')
    open(c,'w').write(s)
s=open(p).read()
if 'Prestium' not in s:
    a='async function outdated(cacheTimeout = TIME_TO_LIVE) {\n'
    assert s.count(a)==1
    s=s.replace(a,a+'    // Prestium: never run "yarn outdated" (would contact the npm registry)\n    return false;\n')
    open(p,'w').write(s)
PY
grep -n -A2 'Prestium' $T/changelog.js $T/packages/index.js
echo PATCH20B-DONE
