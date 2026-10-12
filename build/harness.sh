#!/bin/sh
# writes a single test file: bundled library + example, errors land in getgenv().OasisTestErr
# usage: sh build/harness.sh <out.lua>
cd "$(dirname "$0")/.." || exit 1
node build/bundle.mjs >/dev/null || exit 1
{
    echo 'getgenv().OasisTestErr = "running"'
    echo 'getgenv().OasisWarns = {}'
    echo 'local __warn = warn'
    echo 'warn = function(...) table.insert(getgenv().OasisWarns, table.concat(table.pack(...), " ")) __warn(...) end'
    echo 'local ok, err = xpcall(function()'
    echo 'getgenv().OasisUI_Dev = (function()'
    cat dist/OasisUI.lua
    echo 'end)()'
    cat examples/Example.lua
    echo 'end, debug.traceback)'
    echo 'getgenv().OasisTestErr = ok and "ok" or tostring(err)'
} > "$1"
