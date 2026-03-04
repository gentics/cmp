#!/bin/bash

BRANCH=$(git branch --show-current)
SCRIPT=$(realpath $0)
BASEDIR=$(dirname $SCRIPT)
ROOT=$(realpath $BASEDIR/..)
SRCCONTENTROOT=$ROOT/src/main/hugo
CONTENTROOT=$ROOT/target/hugo
HTMLROOT=$ROOT/target/html

VERSION=$1

MAJOR_VERSION=$(echo "$VERSION" | cut -d. -f1,2)


echo "Generating HTML out of: $ROOT for version: $VERSION for CMP version $MAJOR_VERSION"


mkdir -p $CONTENTROOT
mkdir -p $HTMLROOT
cp -Rf $SRCCONTENTROOT/* $CONTENTROOT


MSYS_NO_PATHCONV=1 docker run -v $CONTENTROOT:/site -v $HTMLROOT:/html/ --rm gentics/hugo-asciidoctor:0.154.5 sh /site/scripts/build.sh $MAJOR_VERSION
