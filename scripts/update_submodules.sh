#!/usr/bin/env bash

git submodule init
git submodule update
git submodule foreach 'if git rev-parse --verify origin/main >/dev/null 2>&1; then git pull -q origin main; else git pull -q origin master; fi'
