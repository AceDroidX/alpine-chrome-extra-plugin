#!/bin/sh

socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9221 &
npm run start