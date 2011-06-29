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

my $nocss = 1 if ( grep { $_ eq "--nocss"} @ARGV );
my $nourlfilter = 1 if ( grep { $_ eq "--nourlfilter"} @ARGV );
die "No lists generated!\n" if ((defined($nourlfilter)) and (defined($nocss)));


# Get old checksum and modification time
my @oldchecksum;
my @oldmodified;

unless (defined($nourlfilter))
{
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
}

unless (defined($nocss))
{
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
}

my $urlfilter = createUrlfilter($list) unless (defined($nourlfilter));
my $elemfilter = createElemfilter($list) unless (defined($nocss));

writeFile("$path/urlfilter.ini",$urlfilter) unless (defined($nourlfilter));
writeFile("$path/element-filter.css",$elemfilter) unless (defined($nocss));



sub createUrlfilter
{
  my $list = shift;
  my @urlfilter;
  my @whitelists;


  foreach my $line (split(/\n/, $list))
  {
    unless ($line =~m/\[.*?\]/i)
    {
      # Convert comments
      if ($line =~ m/^!/)
      {
        # Insert old checksumm
        if ($line =~ m/.Checksum:/)
        {
          ((defined ($oldchecksum[0])) ? ($line) = $oldchecksum[0] : $line =~ s/^\!/#/);
        }
        # Insert old last modified
        elsif ($line =~ m/.Last modified:/)
        {
          (defined ($oldmodified[0])) ? ($line) = $oldmodified[0] : $line =~ s/^\!/#/;
        }
        # Add the rest of comments
        unless ($line =~ m/.Redirect:/)
        {
          $line =~ s/^\!/#/;
          push @urlfilter, $line;
        }
      }
      # Collect whitelists
      elsif ($line =~ m/^@@/)
      {
        # Ignore elemhide whitelists
        unless ($line =~ m/\^\$elemhide$/)
        {
          # Remove whitelist symbols
          $line =~ s/^@@//;
          # Remove vertical bars
          $line =~ s/\|\|//;
          $line =~ s/\|//;
          $line =~ s/\|$//;
          # Remove everything after an caret
          $line =~ s/\^.*//;
          # Remove everything after an asterisk
          $line =~ s/\/\*.*//;

          push @whitelists, $line;
        }
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
          $line =~ s/^\|/https:\/\//;
          $line =~ s/^\|/http:\/\//;
        }
        # Convert domain endings
        $line =~ s/\|$// if ($line =~ m/\|$/);
        # Remove caret
        if ($line =~ m/\^\*/)
        {
          $line =~ s/\^/\//;
        }
        elsif ($line =~ m/\^/)
        {
          $line =~ s/\^/\/\*/;
        }
        # Add beginning asterisk
        $line = "*".$line unless ($line =~ m/^[A-Za-z0-9*]/);
        # Add ending asterisk
        $line = $line."*" unless ($line =~ m/[A-Za-z0-9* ]$/);

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
      # Remove everything after an caret
      $tmpline =~ s/\^.*//;
      # Remove everything after an asterisk  
      $tmpline =~ s/\/\*.*//;
    }
    foreach my $inline (split(/\n/, $whitelists))
    {
      $matcheswhitelist = 1 if (($tmpline =~ m/\Q$inline\E/i) or ($inline =~ m/\Q$tmpline\E/i));
    }

    push @urlfilter, $line unless (defined($matcheswhitelist));
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
    last if ($line =~ m/^\#\-/);
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
    elsif ($line =~ m/^!/)
    {
      # Remove redirect
      unless ($line =~ m/.Redirect:/)
      {
        # Add all header comment lines
        push @elemfilter, $line;
      }
      # Insert old checksumm
      elsif ($line =~ m/.Checksum:/)
      {
        ($line) = $oldchecksum[1] if (defined ($oldchecksum[1]));
        push @elemfilter, $line;
      }
      # Insert old last modified
      elsif ($line =~ m/.Last modified:/)
      {
        ($line) = $oldmodified[1] if (defined ($oldmodified[1]));
        push @elemfilter, $line;
      }
    }
    # Stop at header comment end
    last if ($line =~ m/^\!\-/);
  }
  push @elemfilter, "*/";
  push @elemfilter, "\@namespace \"http://www.w3.org/1999/xhtml\";\n";

  # Create element filter rules
  foreach my $line (split(/\n/, $list))
  {
    unless ($line =~ m/^\!/)
    {
      # Add generic element filters
      if ($line =~ m/^##/)
      {
        $line =~ s/##//;
        # Convert tags to lowercase
        $line =~ s/(^.*[\[\.\#])/\L$1/ if ($line =~ m/^.*[\[\.\#]/);
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