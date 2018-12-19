#!/usr/bin/env bash

stty raw
swift main.swift $1
stty -raw

exit 0
