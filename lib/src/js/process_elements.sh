#!/usr/bin/env bash

X=$PWD
cd `dirname $0`
Y=$PWD
cd $X

node $Y/analyze.js $*
