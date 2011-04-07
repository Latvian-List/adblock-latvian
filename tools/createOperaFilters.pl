#!/usr/bin/env perl

#  Script to convert ABP filters to Opera urlfilter and CSS element filters
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
#  along with this program.  If not, see https://www.gnu.org/licenses/agpl.html.

use strict;
use warnings;
use File::Basename;

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = $ARGV[0];
my $path = dirname($file);
my $list = readFile($file);

my $urlfilter = createUrlfilter($list);
my $elemfilter = createElemfilter($list);

writeFile("$path/urlfilter.ini",$urlfilter);
writeFile("$path/element-filter.css",$elemfilter);



sub createUrlfilter
{
  my $list = shift;
  my @urlfilter;
  my @whitelists;


  # Add urlfilter header
  foreach my $line (split(/\n/, $list))
  {
    if ($line !~m/\[.*?\]/i)
    {
      # Convert comments
      if ($line =~ m/^!/)
      {
        # Remove redirect
        if ($line !~ m/.Redirect:/)
        {
          $line =~ s/\!/#/;
          push @urlfilter, $line;
        }
      }
      else
      {
        push @urlfilter, "[prefs]\nprioritize excludelist=1\n[include]\n*\n[exclude]";
        last;
      }
    }
  }


  foreach my $line (split(/\n/, $list))
  {
    if ($line !~m/\[.*?\]/i)
    {
      # Convert comments
      if ($line =~ m/^!/)
      {
        #$line =~ s/\!/#/;
        #push @urlfilter, $line;
      }
      # Remove lines with types
      elsif ($line =~ m/.\$/)
      {
      }
      # Remove element rules
      elsif (($line =~ m/.##/) or ($line =~ m/^##/))
      {
      }
      # Collect whitelists
      elsif ($line =~ m/^@@/)
      {
        push @whitelists, $line;
      }
      else
      {
        # Convert domain beginnings
        if ($line =~ m/^\|\|/)
        {
          $line =~ s/^\|\|/http:\/\//;
        }
        elsif ($line =~ m/^\|/)
        {
          $line =~ s/^\|/http:\/\//;
        }
        # Add beginning asterisk
        if ($line =~ m/^\//)
        {
          $line = "*".$line;
        }
        # Add ending asterisk
        if ($line =~ m/\/$/)
        {
          $line = $line."*";
        }
        # Convert domain filter endings
        if ($line =~ m/\^$/)
        {
          $line =~ s/\^$/\/*/;
        }

        push @urlfilter, $line;
      }
    }
  }


  #$list = join(@urlfilter);
  #foreach my $line (split(/\n/, $list))
  #{
    # Remove filters that require whitelists
    # ???
  #}

  return join("\n", @urlfilter);
}


sub createElemfilter
{
  my $list = shift;
  my @elemfilter;

  # Add comment section
  push @elemfilter, "/*";
  foreach my $line (split(/\n/, $list))
  {
    # Remove ABP header
    if ($line =~m/\[.*?\]/i)
    {
    }
    elsif ($line =~ m/!/)
    {
      # Remove redirect
      if ($line =~ m/.Redirect:/)
      {
      }
      else
      {
        # Add all header comment lines
        push @elemfilter, $line;
      }
    }
    else
    {
      # Stop at header comment end
      last;
    }
  }
  push @elemfilter, "*/";
  push @elemfilter, "\@namespace \"http://www.w3.org/1999/xhtml\";\n";

  # Create element filter rules
  foreach my $line (split(/\n/, $list))
  {
    if ($line !~ m/\!/)
    {
      # Add generic element filters
      if ($line =~ m/^##/)
      {
        $line =~ s/##//;
        push @elemfilter, $line.",";
      }
    }
  }
  # Remove last comma
  $elemfilter[-1] =~ s/,$//;
  # Add CSS rule
  push @elemfilter,"{ display: none !important; }";

  return join("\n", @elemfilter);
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