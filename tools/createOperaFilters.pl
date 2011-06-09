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
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use File::Basename;

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = $ARGV[0];
my $path = dirname($file);
my $list = readFile($file);

# Get old checksum and modification time
my @oldchecksum;
my @oldmodified;

if (-e "$path/urlfilter.ini")
{
  my $oldlist = readFile("$path/urlfilter.ini");
  foreach my $line (split(/\n/, $oldlist))
  {
    if ($line =~ m/.Checksum:/)
    {
      ($oldchecksum[0])  = $line;
    }
    elsif ($line =~ m/.Last modified:/)
    {
      ($oldmodified[0]) = $line;
    }
  }
  $oldlist = undef;
}

if (-e "$path/element-filter.css")
{
  my $oldlist = readFile("$path/element-filter.css");
  foreach my $line (split(/\n/, $oldlist))
  {
    if ($line =~ m/.Checksum:/)
    {
      ($oldchecksum[1])  = $line;
    }
    elsif ($line =~ m/.Last modified:/)
    {
      ($oldmodified[1]) = $line;
    }
  }
  $oldlist = undef;
}


my $urlfilter = createUrlfilter($list);
my $elemfilter = createElemfilter($list);

writeFile("$path/urlfilter.ini",$urlfilter);
writeFile("$path/element-filter.css",$elemfilter);



sub createUrlfilter
{
  my $list = shift;
  my @urlfilter;
  my @whitelists;


  foreach my $line (split(/\n/, $list))
  {
    if ($line !~m/\[.*?\]/i)
    {
      # Convert comments
      if ($line =~ m/^!/)
      {
        # Insert old checksumm
        if ($line =~ m/.Checksum:/)
        {
          if (defined ($oldchecksum[0]))
          {
            ($line) = $oldchecksum[0];
          }
          else
          {
            $line =~ s/^\!/#/;
          }
        }
        # Insert old last modified
        elsif ($line =~ m/.Last modified:/)
        {
          if (defined ($oldmodified[0]))
          {
            ($line) = $oldmodified[0];
          }
          else
          {
            $line =~ s/^\!/#/;
          }
        }
        # Add the rest of comments
        if ($line !~ m/.Redirect:/)
        {
          $line =~ s/^\!/#/;
          push @urlfilter, $line;
        }
      }
      # Collect whitelists
      elsif ($line =~ m/^@@/)
      {
        $line =~ s/^@@//;
        $line =~ s/\|\|//;
        $line =~ s/\|//;
        $line =~ s/\^.*//;
        $line =~ s/\/\*.*//;

        push @whitelists, $line;
      }
      # Remove lines with types
      elsif ($line =~ m/.\$/)
      {
      }
      # Remove element rules
      elsif (($line =~ m/.##/) or ($line =~ m/^##/))
      {
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
        # Remove caret
        if ($line =~ m/\^\*/)
        {
          $line =~ s/\^/\//;
        }

        push @urlfilter, $line;
      }
    }
  }




  $list = join("\n", @urlfilter);
  undef(@urlfilter);
  my $whitelists = join("\n", @whitelists);
  my $tmpline = "";
  my $matcheswhitelist;

  foreach my $line (split(/\n/, $list))
  {
    # Remove filters that require whitelists
    ($tmpline) = $line;
    $tmpline =~ s/http:\/\///;
    while ($tmpline =~ m/\/\*/)
    {
      $tmpline =~ s/\^.*//;
      $tmpline =~ s/\/\*.*//;
    }
    foreach my $inline (split(/\n/, $whitelists))
    {
      $matcheswhitelist = 1 if ($tmpline =~ m/\Q$inline\E/);
    }

    if (!defined($matcheswhitelist))
    {
      push @urlfilter, $line;
    }
    $matcheswhitelist = undef;

  }

  # Create rules for subdomains
  $list = join("\n", @urlfilter);
  undef(@urlfilter);
  foreach my $line (split(/\n/, $list))
  {
    push @urlfilter, $line;
    if ($line =~ m/^http\:\/\//)
    {
      $line =~ s/http\:\/\//\*\./;
      push @urlfilter, $line;
    }
  }


  $list = join("\n", @urlfilter);
  # Add urlfilter header
  my $linenr = 0;
  foreach my $line (split(/\n/, $list))
  {
    $linenr++;
    if ($line =~ m/^\#\-/)
    {
      last;
    }
  }
  splice (@urlfilter, $linenr, 0, "[prefs]\nprioritize excludelist=1\n[include]\n*\n[exclude]");

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
      if ($line !~ m/.Redirect:/)
      {
        # Add all header comment lines
        push @elemfilter, $line;
      }
      # Insert old checksumm
      elsif ($line =~ m/.Checksum:/)
      {
        if (defined ($oldchecksum[1]))
        {
          ($line) = $oldchecksum[1];
        }
        push @elemfilter, $line;
      }
      # Insert old last modified
      elsif ($line =~ m/.Last modified:/)
      {
        if (defined ($oldmodified[1]))
        {
          ($line) = $oldmodified[1];
        }
        push @elemfilter, $line;
      }
    }
    if ($line =~ m/^\!\-/)
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