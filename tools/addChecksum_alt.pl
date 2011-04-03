#!/usr/bin/env perl

# Copyright 2011 Wladimir Palant
# Adapted by anonymous74100
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;
use Digest::MD5 qw(md5_base64);
use POSIX qw(strftime);

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = $ARGV[0];
my $data = readFile($file);

# Get existing checksum
$data =~ /^.*#\s*checksum[\s\-:]+([\w\+\/=]+).*\n/gmi;
my $oldchecksum = $1;

# Remove already existing checksum
$data =~ s/^.*#\s*checksum[\s\-:]+([\w\+\/=]+).*\n//gmi;

# Calculate new checksum: remove all CR symbols and empty
# lines and get an MD5 checksum of the result (base64-encoded,
# without the trailing = characters)
my $checksumData = $data;
$checksumData =~ s/\r//g;
$checksumData =~ s/\n+/\n/g;

# Calculate new checksum
my $checksum = md5_base64($checksumData);

# If the old checksum matches the new one die
if ($checksum eq $oldchecksum)
{
  die "List has not changed.\n";
}

# Update the date and time.
my $updated = strftime("%d.%m.%Y. %H:%M UTC", gmtime);
$data =~ s/(^.*#.*Last modified:\s*)(.*)\s*$/$1$updated/gmi;

# Recalculate the checksum as we've altered the date
$checksumData = $data;
$checksumData =~ s/\r//g;
$checksumData =~ s/\n+/\n/g;
$checksum = md5_base64($checksumData);

# Insert checksum into the file
$data =~ s/(\r?\n)/$1# Checksum: $checksum$1/;

writeFile($file, $data);

sub readFile
{
  my $file = shift;

  open(local *FILE, "<", $file) || die "Could not read file '$file'\n";
  binmode(FILE);
  local $/;
  my $result = <FILE>;
  close(FILE);

  return $result;
}

sub writeFile
{
  my ($file, $contents) = @_;

  open(local *FILE, ">", $file) || die "Could not write file '$file'\n";
  binmode(FILE);
  print FILE $contents;
  close(FILE);
}