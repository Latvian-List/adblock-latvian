#!/usr/bin/env perl

#  Script to convert ABP filters to IE TPL
#  Copyright (C) 2011  anonymous74100
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
# Generate TPL filename
my $tplfilename = fileparse("$file", qr/\.[^.]*/).".tpl";


my $oldchecksum;
my $oldmodified;
# Get old checksum and modification time
if (-e "$path/$tplfilename")
{
  my $oldlist = readFile("$path/$tplfilename");
  foreach my $line (split(/\n/, $oldlist))
  {
    if ($line =~ m/.Checksum:/)
    {
      ($oldchecksum)  = $line;
    }
    elsif ($line =~ m/.Last modified:/)
    {
      ($oldmodified) = $line;
    }
  }
  $oldlist = undef;
}


my $tpl = createTPL($list);


# Write TPL
writeFile("$path/$tplfilename",$tpl);



sub createTPL
{
  my $list = shift;
  my @tpl;
  my $expires = 1;

  push @tpl, "msFilterList";

  foreach my $line (split(/\n/, $list))
  {
    if ($line !~m/\[.*?\]/i)
    {
      # Convert comments
      if ($line =~ m/^!/)
      {
        # Get expire value
        if ($line =~ m/.Expires:/)
        {
          ($expires) = $line =~ /(\d+)/;
        }
        # Insert old checksumm
        elsif ($line =~ m/.Checksum:/)
        {
          (defined ($oldchecksum)) ? ($line) = $oldchecksum : $line =~ s/^\!/#/;
          push @tpl, $line;
        }
        # Insert old last modified
        elsif ($line =~ m/.Last modified:/)
        {
          (defined ($oldmodified)) ? ($line) = $oldmodified : $line =~ s/^\!/#/;
          push @tpl, $line;
        }
        # Remove redirect
        elsif ($line !~ m/.Redirect:/)
        {
          $line =~ s/\!/#/;
          push @tpl, $line;
        }
      }
      # Remove lines with types except third-party
      elsif (($line =~ m/.\$/) and ($line !~ m/.\$third-party/))
      {
      }
      # Remove element rules
      elsif (($line =~ m/.##/) or ($line =~ m/^##/))
      {
      }
      else
      {
        # Convert domain wide rules
        if (($line =~ m/^\|/) or ($line =~ m/^@@\|/))
        {
          # Seperate domain from path
          $line =~ s/\// \//;
          # Convert domain beginnings
          if ($line =~ m/^\|\|/)
          {
            $line =~ s/^\|\|/-d /;
          }
          elsif ($line =~ m/^\|/)
          {
            # Detect if filter already has "http" in it
            ($line =~ m/^\|http/) ? $line =~ s/^\|/- / : $line =~ s/^\|/- http:\/\//;
          }
          # Convert whitelists
          elsif ($line =~ m/^@@/)
          {
            $line =~ s/^@@\|\|/+d /;
          }
          elsif ($line =~ m/^@@\|/)
          {
            $line =~ s/^@@\|/+d /;
          }
        }
        # Convert generic whitelists
        elsif ($line =~ m/^@@/)
        {
          $line =~ s/^@@/+ /;
        }
        # Convert generic rules
        elsif ($line !~ m/^$/)
        {
          $line = "- ".$line;
        }
        # Convert third party rules to first party rules
        $line =~ s/\$third-party// if ($line =~ m/.\$third-party/);
        # Remove ending caret
        if ($line =~ m/\^$/)
        {
          $line =~ s/\^$//;
        }
        # Remove ending asterisk
        elsif ($line =~ m/\/\*$/)
        {
          $line =~ s/\/\*$/\//;
        }
        # Remove ending caret in middle of rule
        $line =~ s/\^\*/ \/*/ if ($line =~ m/.\^\*/);
        # Remove ending vertical bars
        $line =~ s/\|$//;
        push @tpl, $line;
      }

    }
  }
  # Add expires value
  splice (@tpl, 1, 0, ": Expires=$expires");

  return join("\n", @tpl);
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