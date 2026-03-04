#!/bin/sh

set -o nounset
set -o errexit

SCRIPT=$(realpath $0)
BASEDIR=$(dirname $SCRIPT)
ROOT=$(realpath $BASEDIR/..)

MAJOR_VERSION=$1

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

HUGO_PARAMS_CMPVERSION=$MAJOR_VERSION hugo --baseURL https://www.gentics.com/guides/$MAJOR_VERSION/  && echo "done generating"

echo "Move output files"
rm /html/* -Rf

mkdir -p /html/$MAJOR_VERSION
mv output/* /html/$MAJOR_VERSION


echo "Finished"
#chmod -R a+rwx $ROOT/static/docs
