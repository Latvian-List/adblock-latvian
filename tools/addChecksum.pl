#!/usr/bin/env perl

# Copyright 2011 Wladimir Palant
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
use Path::Tiny;
use Digest::MD5 qw(md5_base64);
use Encode qw(encode_utf8);
use POSIX qw(strftime);
use feature 'unicode_strings';

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = shift;

die "Specified file: $file doesn't exist!\n" unless (-e $file);

my $data = path($file)->slurp_utf8;

# Remove already existing checksum
$data =~ s/^.*!\s*checksum[\s\-:]+([\w\+\/=]+).*\n//gmi;

# Update the date and time.
my $updated = strftime("%Y-%m-%d %H:%M UTC", gmtime);
$data =~ s/(^.*!.*(Last modified|Updated):\s*)(.*)\s*$/$1$updated/gmi if ($data =~ m/^.*!.*(Last modified|Updated)/gmi);

# Update version
my $version = strftime("%Y%m%d%H%M" ,gmtime);
$data =~ s/^.*!\s*Version:.*/! Version: $version/gmi;

path($file)->spew_utf8($data);
