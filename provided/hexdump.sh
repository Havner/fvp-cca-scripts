#!/bin/sh

exec hexdump -v -e '8/1 "%02X ""\n"' "$@"
