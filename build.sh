#!/bin/bash

if ! command -v craftos >/dev/null 2>&1; then
    echo "Error: craftos-pc ('craftos') not found, please install it."
    exit 1
fi

craftos --headless --exec "shell.run('/build-headless.lua')" -c="./"
