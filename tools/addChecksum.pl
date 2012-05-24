#!/usr/bin/env perl

# Copyright 2012 anonymous74100
# Portions copyright 2011 Wladimir Palant
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
use File::Slurp;
use Getopt::Long qw(:config no_auto_abbrev);
use Digest::MD5 qw(md5_base64);
use POSIX qw(strftime);
use feature 'unicode_strings';

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = my $opera = '';
GetOptions ('<>' => \&{$file = shift}, 'opera' => \$opera);    # Get command line options

die "Specified file: $file doesn't exist!\n" unless (-e $file);

my $commentsymbol = '!';
$commentsymbol = ';' if $opera;

my $data = read_file($file, binmode => ':utf8' );

# Get existing checksum
$data =~ /^.*$commentsymbol\s*checksum[\s\-:]+([\w\+\/=]+).*\n/gmi;
my $oldchecksum = $1;

# Remove already existing checksum
$data =~ s/^.*$commentsymbol\s*checksum[\s\-:]+([\w\+\/=]+).*\n//gmi;

# Calculate new checksum: remove all CR symbols and empty
# lines and get an MD5 checksum of the result (base64-encoded,
# without the trailing = characters)
my $checksumData = $data;
$checksumData =~ s/\r//g;
$checksumData =~ s/\n+/\n/g;

# Calculate new checksum
my $checksum = md5_base64($checksumData);

# If the old checksum matches the new one die
die "List has not changed.\n" if ($checksum eq $oldchecksum);

# Update the date and time.
my $updated = strftime("%d.%m.%Y. %H:%M UTC", gmtime);
$data =~ s/(^.*$commentsymbol.*Last modified:\s*)(.*)\s*$/$1$updated/gmi;

# Recalculate the checksum as we've altered the date
$checksumData = $data;
$checksumData =~ s/\r//g;
$checksumData =~ s/\n+/\n/g;
$checksum = md5_base64($checksumData);

# Insert checksum into the file
$data =~ s/(\r?\n)/$1$commentsymbol Checksum: $checksum$1/;

write_file($file, {binmode => ':utf8'}, $data);