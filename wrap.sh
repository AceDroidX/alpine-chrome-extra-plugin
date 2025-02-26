#!/bin/sh

Xvfb :7 -screen 0 1336x768x24 2>/dev/null &
sleep 3
socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9221 &
/home/chrome/.bun/bin/bun run index.ts
# bash