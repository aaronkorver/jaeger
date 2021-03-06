#!/bin/bash

# stage-file copies the file $1 with the specified path $2
# if no file exists it will silently continue
function stage-file {
    if [ -f $1 ]; then
        echo "Copying $1 to $2"
        cp $1 $2
    else
        echo "$1 does not exist. Aborting."
        exit 1
    fi
}

# stage-platform-files stages the different the platform ($1) into the package
# staging dir ($2). If you pass in a file extension ($3) it will be used when 
# copying on the source
function stage-platform-files {
    local PLATFORM=$1
    local PACKAGE_STAGING_DIR=$2
    local FILE_EXTENSION=$3
    
    stage-file ./cmd/standalone/standalone-$PLATFORM $PACKAGE_STAGING_DIR/jaeger-standalone$FILE_EXTENSION
    stage-file ./cmd/agent/agent-$PLATFORM $PACKAGE_STAGING_DIR/jaeger-agent$FILE_EXTENSION
    stage-file ./cmd/query/query-$PLATFORM $PACKAGE_STAGING_DIR/jaeger-query$FILE_EXTENSION
    stage-file ./cmd/collector/collector-$PLATFORM $PACKAGE_STAGING_DIR/jaeger-collector$FILE_EXTENSION
    echo "Copying jaeger-ui-build to $PACKAGE_STAGING_DIR"
    cp -r jaeger-ui-build $PACKAGE_STAGING_DIR
}

# package pulls built files for the platform ($1). If you pass in a file 
# extension ($2) it will be used on the binaries
function package {
    local PLATFORM=$1
    local FILE_EXTENSION=$2

    local PACKAGE_STAGING_DIR=jaeger-$VERSION-$PLATFORM-amd64
    mkdir $PACKAGE_STAGING_DIR

    stage-platform-files $PLATFORM $PACKAGE_STAGING_DIR $FILE_EXTENSION

    local ARCHIVE_NAME="$PACKAGE_STAGING_DIR.tar.gz"
    echo "Packaging into $ARCHIVE_NAME:"
    tar -czvf ./deploy/$ARCHIVE_NAME $PACKAGE_STAGING_DIR
}

# script start
if [ "$DEPLOY" != true ]; then
    echo "Skipping the packaging of binaries as \$DEPLOY was not true."
    exit 0
fi

set -e

DEPLOY_STAGING_DIR=./deploy-staging
VERSION="$(make echo-version | awk 'match($0, /([0-9]*\.[0-9]*\.[0-9]*)$/) { print substr($0, RSTART, RLENGTH) }')"
echo "Working on version: $VERSION"

# make needed directories
rm -rf deploy $DEPLOY_STAGING_DIR
mkdir deploy
mkdir $DEPLOY_STAGING_DIR

INDEX_HTML=jaeger-ui-build/build/index.html
if [ ! -f $INDEX_HTML ]; then
    echo "Cannot find UI assets, e.g. $INDEX_HTML. Aborting."
    exit 1
fi

package linux
package darwin
package windows .exe
