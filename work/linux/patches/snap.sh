#!/bin/bash

mkdir -p snaps

snapname=$1

mkdir -p snaps/$snapname

cp vmlinux    snaps/$snapname
cp System.map snaps/$snapname
or1k-elf-objdump --no-addresses --no-show-raw-insn -d vmlinux > snaps/$snapname/vmlinux.S
or1k-elf-readelf -a vmlinux                                   > snaps/$snapname/vmlinux.all
