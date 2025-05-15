#!/usr/bin/env bash

set -e

docker build -t lambda-python-builder:latest .

mkdir ../build
cp ./* ../build/
cd ../build/

docker run -it -v $PWD:/app  lambda-python-builder:latest

cp ./code.zip ../src/

cd -
rm -rf ../build/
