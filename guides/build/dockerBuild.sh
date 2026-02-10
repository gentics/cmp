#!/bin/bash

BRANCH=$(git branch --show-current)
SCRIPT=$(realpath $0)
BASEDIR=$(dirname $SCRIPT)
ROOT=$(realpath $BASEDIR/..)
SRCCONTENTROOT=$ROOT/src/main/hugo
CONTENTROOT=$ROOT/target/hugo
HTMLROOT=$ROOT/target/html

echo "Generating HTML out of: " $ROOT

mkdir -p $CONTENTROOT
mkdir -p $HTMLROOT
cp -Rf $SRCCONTENTROOT/* $CONTENTROOT


MSYS_NO_PATHCONV=1 docker run -v $CONTENTROOT:/site -v $HTMLROOT:/html/ --user 1000:1000 --rm gentics/hugo-asciidoctor /site/scripts/build.sh
#MSYS_NO_PATHCONV=1 docker run -v $CONTENTROOT:/site --user 1000:1000 --rm gentics/hugo-asciidoctor /site/scripts/build.sh
