#!/usr/bin/env perl

# Copyright 2011 Wladimir Palant and Michael
# Adapted by anonymous74100
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;
use File::Basename;

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = $ARGV[0];
my $data = readFile($file);
my $path = dirname($file);

# Convert ABP list to TPL
$data = convertToTPL($data);

# Generate TPL filename
my $tplfilename = fileparse("$file", qr/\.[^.]*/).".tpl";
# Write TPL
writeFile("$path/$tplfilename",$data);


sub convertToTPL
{
  my $data = shift;

  my @result;

  #Add necessary definitions
  push @result, "msFilterList";
  push @result, ": Expires=2";

  foreach my $line (split(/\n/, $data))
  {
    my $original = $line;
    #Translate comments, not including Adblock Plus specific values
    if ($line =~m/\[.*?\]/i)
    {
    }
    elsif ($line =~ m/^!/)
    {
      if ($line =~m/Expires/i)
      {
        #Eventually use this for the : Expires= value
      }
      elsif ($line !~ m/\!\s*checksum/i)
      {
        $line =~ tr/\!/#/;
        push @result, $line;
      }
    }
    else
    {
      #Translate domain blocks
      if ($line =~ /^(|@@)\|\|.*?\^/)
      {
        $line =~ s/\^/ /;
      }
      elsif ($line =~ /^(|@@)\|\|.*?\//)
      {
        $line =~ s/\// \//;
      }
      #Remove unnecessary asterisks
      $line =~ s/\*$//;
      $line =~ s/ \*/ /;
      #Remove unnecessary slashes and spaces
      $line =~ s/ \/$//;
      $line =~ s/ $//;

      #Remove beginning and end anchors
      unless ($line =~ m/^\|\|/)
      {
        $line =~ s/^\|//;
      }
      $line =~ s/\|($|\$)//;

      #Translate the script option to "*.js"
      $line =~ s/\$script$/\*\.js/;

      #Translate whitelists, making them wider if necessary
      if ($line =~ m/^@@\|\|.*?(^|\/)/)
      {
        $line =~ s/@@\|\|/\+d /;
        #Remove all options
        $line =~ s/\$.*?$//;
      }
      #Comment out all other whitelists, as a domain must be specified in Internet Explorer
      elsif ($line =~ m/^@@/)
      {
        $line = "# " . $original;
      }
      #Comment out all filters with options or element hiding rules, as this functionality is not available in Internet Explorer
      elsif ($line =~ m/(\$|##)/)
      {
        $line = "# " . $original;
      }
      #Comment out lone third party options
      elsif ($line =~ s/\$third-party$//)
      {
        $line = "# " . $original;
      }
      #Translate all domain filters
      elsif ($line =~ m/^\|\|.*?(^|\/)/)
      {
        $line =~ s/^\|\|/\-d /;
      }
      #Translate all other double anchored filters
      elsif ($line =~ m/^\|\|/)
      {
        $line =~ s/^\|\|/\- http:\/\//;
      }
      #Translate all remaining filters as general
      else
      {
        $line = "- " . $line;
      }
      push @result, $line;
    }
  }

  return join("\n", @result) . "\n";
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