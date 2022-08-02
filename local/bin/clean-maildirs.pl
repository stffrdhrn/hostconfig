#!/usr/bin/perl
use Date::Parse;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use Getopt::Long;

use strict;

# Searches maildirs for files that we want to delete based
# on the config listed below.  The Idea is that our mbsync
# will notice the files are missing and delete from from IMAP.
# A issue with gmail is it seems we need to delete the same mail
# from all tags/folders to actuall delete the file.
#
# Maildir file format
#  new - just came in
#  cur - existing
#  tmp - for outgoing only
#
# File format:
# Example: openrisc/cur/1620593553.17519_267.antec,U=256:2,FS
#                       \                         /
#                        -- unique id ------------
# Unique id
#  {time}.{pid}_{count}.{hostname}
#
# time  - unix timestamp of when the file was created
# pid   - the pid of the sync process
# count - msg count for this sync session, increments each message
# host  - the hostname
#
# U={UID}
#
# UID - a UID but not the one from the mbsync logs. See below
#       this is the near side UID.
#
# :2,{flags}
#
# flags - flags indicating the mail status
#  D - Draft
#  F - Flagged
#  R - Replied
#  S - Seen
#  T - Trashed
#
# Code: https://github.com/djnym/isync/blob/master/src/drv_maildir.c#L1038
#
##########################################################################
#
# Mail sync logs:
#
# The mailsync logs contain logs in this format:
#
# * 11704 FETCH (UID 58883 FLAGS ())
# * 11705 FETCH (UID 58887 FLAGS ())
# * 11706 FETCH (UID 58889 FLAGS (\Seen))
#
# * 11704 FETCH (UID 56959 FLAGS ())
# * 11705 FETCH (UID 56960 FLAGS (\Seen))
# * 11706 FETCH (UID 56962 FLAGS ())
#
# * 11705 FETCH (UID 56960 FLAGS (\Deleted \Seen))
#
# This is the log of the remote IMAP syncing. The format is
# * {idx} FETCH (UID {UID} FLAGS ({flags}))
#
# idx   - the index of the fetch command for this mail box
#         beware this overlaps for mailboxes
# UID   - the far side mail UID, See below
# flags - The far side flags
#
#
###########################################################################
#
# MAPPING FAR-SIDE NEAR-SIDE UIDs
#
# mbsync stores a map file, i.e. gmail/Inbox/.mbsyncstate
# the format looks like:
# ...
# 56959 15533 S
# 56962 15536
# 56964 15538
# 56965 15539
# 56967 15541
# \far/ \near/ \flags/
#
# far  - the far side UID, this is what you see in logs
# near - the near side UID, this is what we see in the maildir
# flags - the current flags we know of
#

Log::Log4perl->easy_init({
  level => $INFO,
  file  => 'STDOUT',
  layout => '%d{yyyy-MM-dd HH:mm:ss.SSS} %p %P - %m%n',
});
my $logger = Log::Log4perl->get_logger('io.stffrdhrn.maildir.cleaner');

## CONFIG ##
# Where to look
my $MAIL_PATH="/home/shorne/.mail/gmail";
my @subdirs = ('cur', 'new', 'tmp');

# What files can and can't contain to be considered noise
my @includes = ('List-ID: .*linux-kernel\.vger\.kernel\.org',
                'List-Id: .*kbuild-all\.lists\.01\.org',
                'List-Id: .*buildroot\.busybox\.net',
                'List-Id: .*gcc-patches\.gcc\.gnu\.org',
                'List-Id: .*\.sourceware\.org', # binutils, libc-alpha, newlib, gdb
                'List-Id: .*qemu-devel\.nongnu\.org');
my @excludes = ('^To: .*shorne', '^From: .*shorne', '^Cc: .*shorne', 'or1k', 'openrisc');

# How old we want files to be
my $max_days = 90;

# How many files we want to select at a time
my $max_files = 1000;

my $dryrun = 0;

#######################

sub get_headers {
  my ($file) = @_;

  my $lines = [];

  open(my $fh, "$file") || die "Can't open '$file': $!";
  while (<$fh>) {
    chomp;
    last if ($_ eq ''); # don't search mails after first blank line (just headers)
    push @$lines, $_;
  }
  close $fh;

  return $lines;
}

sub matches_patterns {
  my ($lines) = @_;

  foreach my $include (@includes) {
    if (grep { /$include/i } @$lines) {
      foreach my $exclude (@excludes) {
        return 0 if (grep { /$exclude/ } @$lines);
      }
      return 1;
    }
  }
  return 0;
}

# Parse date in the form: Wed, 9 Nov 1994 09:50:32 -0500
sub past_date {
  my ($lines, $past_ts) = @_;

  foreach (@$lines) {
    if (/^Date: (.*)/) {
      my $ts = str2time($1);
      # print "date: $1 -> $ts\n";
      return $past_ts > $ts;
    }
  }
  return 0;
}

sub get_message_id {
  my ($lines) = @_;

  foreach (@$lines) {
    if (/^Message-Id: (.*)/i) {
      return "$1";
    }
  }
  return "%no-message-id%";
}

# Search for old trashable mails
# in a maildir http://cr.yp.to/proto/maildir.html
sub run_search_worker {
  my ($maildir) = @_;

  my $now = time;
  my $past_ts = $now - ($max_days * 60 * 60 * 24);
  my $files = 0;

  foreach my $subdir (@subdirs) {
    opendir(my $dh, "$maildir/$subdir") || die "Can't open '$maildir/$subdir': $!";
    while (readdir $dh) {
      # Skip anything already [T]rashed
      next if (/:2,[A-Z]*T[A-Z]*/);

      my $file = "$maildir/$subdir/$_";
      my $headers = get_headers($file);

      if (matches_patterns($headers) && past_date($headers, $past_ts)) {
        $logger->info("$file ". get_message_id($headers));
        if (!$dryrun) {
          unlink $file or die "Could not unlink $file: $!";
        }
        $files++;
      }
      last if ($files > $max_files);
    }
    closedir $dh;
  }
}

# Fork workers to search each maildir
sub fork_search_workers {
  my ($maildirs) = @_;

  my $pid;

  foreach my $maildir (@$maildirs) {
    $pid = fork();
    if ($pid == 0) {
      $logger->info("Worker searching $maildir ...");
      run_search_worker($maildir);
      exit 0;
    } else {
      $logger->info("Parent started $pid : $maildir ...");
    }
  }

  $logger->info("Waiting for workers...");
  do {
    $pid = waitpid -1, 0;
    $logger->info("$pid complete");
  } while ($pid > 0);
}

# Find all maildirs in a path
sub find_maildirs {
  my ($path, $maildirs) = @_;

  if (-d "$path/cur") {
    push @$maildirs, $path;
    return;
  }

  opendir(my $dh, $path) || die "Can't open '$path': $!";
  while (readdir $dh) {
    next if ($_ eq '.' || $_ eq '..');
    if (-d "$path/$_") {
      find_maildirs("$path/$_", $maildirs);
    }
  }
  closedir $dh;
}

# Main
# loop over dirs and files looking for what we want.

GetOptions ("dryrun"  => \$dryrun)   # flag
  or die("Error in command line arguments\n");

$logger->info("Running cleanup on path: $MAIL_PATH, max_days: $max_days, max_files: $max_files, dryrun; $dryrun");

my @maildirs = ();
find_maildirs($MAIL_PATH, \@maildirs);
fork_search_workers(\@maildirs);
