#!/bin/bash

DATE=$(date +"%Y%m%d")
DIR=$(dirname $0)

since_tag=$1; shift
output_dir="$DIR/or1k-$DATE"

if [ "$1" ] ; then
  until_tag=$1; shift
else
  until_tag=HEAD
fi

if [ -z "$since_tag" ] ; then
  echo "usage: $0 [since_tag]"
  exit 1
fi

rm $output_dir/*.patch
git format-patch --cover-letter $@ -o $output_dir $since_tag..$until_tag
./scripts/checkpatch.pl $output_dir/*.patch
