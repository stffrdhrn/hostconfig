#!/bin/bash

# Creates a linux PR for linus, for this to work we need our .git/config to
# be configured with an https pull url and our git: pushUrl as follows:
#
# [remote "openrisc"]
#        url = https://github.com/openrisc/linux.git
#        pushUrl = git@github.com:openrisc/linux.git
#        fetch = +refs/heads/*:refs/remotes/openrisc/*
#

since=$1

if [ -z "$since" ]; then
  echo "Usage: $0 <since>"
  git lo
  exit 1
fi

subject=$(git tag -l for-linus --format='%(contents)' | head -n1)

echo "To: Linus Torvalds <torvalds@linux-foundation.org>"
echo "Cc: Linux OpenRISC <linux-openrisc@vger.kernel.org>, LKML <linux-kernel@vger.kernel.org>"
echo "Subject: [GIT PULL] $subject"
echo

echo "Hello Linus,"
echo
echo "Please consider for pull,"
echo

git request-pull $since openrisc for-linus

>&2 echo "now process this with: mutt -E -H <file>"
