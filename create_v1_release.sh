#!/bin/bash

MAJOR="$1"
MINOR="$2"
PATCH="$3"
VERSION_STRING="$MAJOR.$MINOR.$PATCH"
RELEASE_BRANCH="release-$VERSION_STRING"

git checkout -b "$RELEASE_BRANCH" v1

echo "StudyServer::Application.config.erica_version = [$MAJOR,$MINOR,$PATCH]" > config/initializers/00_version.rb
git commit -am "Bump version to $VERSION_STRING"

git checkout master
git merge --no-ff "$RELEASE_BRANCH"
git tag -a "$VERSION_STRING" -m "Tag release version $VERSION_STRING"
git push
git push --tags

git checkout v1
git merge --no-ff "$RELEASE_BRANCH"
git push

git branch -d "$RELEASE_BRANCH"
