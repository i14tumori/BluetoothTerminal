#!/usr/bin/env bash

stty raw
swift main.swift
stty -raw

exit 0
