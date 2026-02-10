#!/bin/sh

set -o nounset
set -o errexit

SCRIPT=$(realpath $0)
BASEDIR=$(dirname $SCRIPT)
ROOT=$(realpath $BASEDIR/..)

echo "Building css"
cd $ROOT/themes/gentics
yarn install && yarn build
#yarn build

ls -ltrahR static/styles/
ls -ltrahR static/js/

mkdir -p $ROOT/static/

cp -R /site/assets/* $ROOT/static/


cd $ROOT/themes/gentics

echo "Building with hugo"
cd $ROOT

ls -ltrah ./

hugo && echo "done generating"

echo "Move output files"
rm /html/* -Rf
mv output/* /html/

echo "Finished"
#chmod -R a+rwx $ROOT/static/docs
