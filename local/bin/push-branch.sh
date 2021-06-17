#!/usr/bin/bash
#
# Push a branch to travis and for-next

set -ev

BRANCH=$1

if [[ -z $BRANCH ]] ; then
  echo "usage: $0 <branch>"
  exit 1
fi

# Push changes to for-next (will go to linux-next)
git checkout for-next
git reset --hard $BRANCH
git push -f shorne HEAD
git push -f openrisc HEAD

# Push changes to travis (will be build tested)
git checkout travis
git reset --hard $BRANCH
git am patches/0001-Add-travis-cia-for-openrisc-kernel.patch
git push -f shorne HEAD

git checkout $BRANCH
