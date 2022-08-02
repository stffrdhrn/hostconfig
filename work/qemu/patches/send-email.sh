#!/bin/bash

git send-email --to qemu-devel --cc-cmd ./scripts/get_maintainer.pl $@
