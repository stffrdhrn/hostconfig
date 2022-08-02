#!/bin/bash

git send-email --to linux-kernel --cc-cmd ./scripts/get_maintainer.pl $@
