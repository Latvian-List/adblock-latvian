#!/usr/bin/env perl

#  Script to convert ABP filters to Opera urlfilter and CSS element filters
#  Copyright (C) 2012  anonymous74100
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use File::Basename;

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = $ARGV[0];
my $path = dirname($file);
my $list = readFile($file);

# File names
my $urlfilterfile = "$path/urlfilter.ini";
my $cssfile = "$path/element-filter.css";

my $nocss = 1 if ( grep { $_ eq "--nocss"} @ARGV );
my $nourlfilter = 1 if ( grep { $_ eq "--nourlfilter"} @ARGV );
die "No lists generated!\n" if ((defined $nourlfilter) and (defined $nocss));


my $urlfilter = createUrlfilter($list) unless (defined $nourlfilter);
my $elemfilter = createElemfilter($list) unless (defined $nocss);

# Warn if a file won't be generated
print "Urlfilter won't be generated!\n" unless (defined $urlfilter);
print "CSS won't be generated!\n" unless (defined $elemfilter);

# Write generated files
writeFile($urlfilterfile,$urlfilter) unless ((defined $nourlfilter) or (!defined $urlfilter));
writeFile($cssfile,$elemfilter) unless ((defined $nocss) or (!defined $elemfilter));



sub createUrlfilter
{
  my $list = shift;
  my $urlfilter = "";

  # Get old checksum and modification time
  if (-e $urlfilterfile)
  {
    my $oldlist = readFile($urlfilterfile);
    my $oldchecksum = $1 if $oldlist =~ m/(Checksum:.*)$/gim;
    my $oldmodified = $1 if $oldlist =~ m/((Last modified|Updated):.*)$/gim;
    undef $oldlist;
  }

  my $whitelists = $1 if $list =~ m/^(@@\S*(\$elemhide)?\r?\n)/gm;    # Collect whitelists


  $list =~ s/\[.*\]\n//gm;    # Remove ABP header
  $list =~ s/^@@.*\n?//gm;    # Remove whitelists
  $list =~ s/^.*##.*\n?//gm;    # Remove element filters
  $list =~ s/^.*\$.*\n?//gm;    # Remove filters with types

  $list =~ s/^!/;/gm;    # Convert comments
  $list =~ s/^(;\s)Title:\s/$1/mi;    # Normalize title
  $list =~ s/^(;\sRedirect\n)//gmi;    # Remove redirect comment

#  $list =~ s/^(;\s)(Checksum:.*)$/$1$oldchecksum/gmi if (defined $oldchecksum);    # Insert old checksum
#  $list =~ s/^(;\s)((Last modified|Updated):.*)$/$1$oldmodified/gmi if (defined $oldmodified);    # Insert old modification date/time

  $list =~ s/^([^;|].*$)/\*$1/gm;    # Add beginning asterisk
  $list =~ s/^([^;]\S*[^|*])$/$1\*/gm;    # Add ending asterisk
  $list =~ s/^\|([^|].*)$/$1/gm;    # Remove beginning pipe
  $list =~ s/^([^;].*)\|$/$1/gm;    # Remove ending pipe

  $list =~ s/^(;\s*?)\n/\[prefs\]\nprioritize excludelist=1\n\[include\]\n\*\n\[exclude\]\n$1\n/m;    # Add urlfilter header


  # Parse whitelists
  # ?










  return $list;
}


sub createElemfilter
{
  my $list = shift;

  # Get old checksum and modification time
  if (-e $cssfile)
  {
    my $oldlist = readFile($cssfile);
    my $oldchecksum = $1 if $oldlist =~ m/(Checksum:.*)$/gim;
    my $oldmodified = $1 if $oldlist =~ m/((Last modified|Updated):.*)$/gim;
    undef $oldlist;
  }

  $list =~ s/^(?!##|^!).*\n?//gm;    # Leave only generic element filters and comments

  $list =~ s/^##//gm;    # Remove beginning number signs
  $list =~ s/(^.*[\[.#])/\L$1/gmi;    # Convert tags to lowercase


  $list =~ s/^([^!].*[^,])$/$1,/;    # Add commas


  $list =~ s/^(!\s*?)\n/\@namespace "http:\/\/www.w3.org\/1999\/xhtml"\n$1\n;/m;    # Add xml namespace declaration
  # Add CSS rule
  # ?

  # Convert comments
  # ?

  return $list;
}


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