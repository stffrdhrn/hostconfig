#!/bin/bash

since=$1

if [ -z "$since" ]; then
  echo "Usage: $0 <since>"
  git lo
  exit 1
fi

echo "To: Linus Torvalds <torvalds@linux-foundation.org>"
echo "Cc: Openrisc <openrisc@lists.librecores.org>, LKML <linux-kernel@vger.kernel.org>"
echo "Subject: [GIT PULL] OpenRISC fixes/updates for ~$since"
echo

echo "Hello Linus,"
echo
echo "Please consider for pull,"
echo

git request-pull $since openrisc for-linus

>&2 echo "now process this with: mutt -E -H <file>"
