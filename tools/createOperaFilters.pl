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
use List::MoreUtils qw{lastidx firstval};

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = $ARGV[0];
my $path = dirname($file);
my $list = readFile($file);

my $nocss = 1 if ( grep { $_ eq "--nocss"} @ARGV );
my $nourlfilter = 1 if ( grep { $_ eq "--nourlfilter"} @ARGV );
die "No lists generated!\n" if ((defined $nourlfilter) and (defined $nocss));


my $urlfilter = createUrlfilter($list) unless (defined $nourlfilter);
my $elemfilter = createElemfilter($list) unless (defined $nocss);

# Warn if a file won't be generated
print "Urlfilter won't be generated!\n" unless (defined $urlfilter);
print "CSS won't be generated!\n" unless (defined $elemfilter);

# Write generated files
writeFile("$path/urlfilter.ini",$urlfilter) unless ((defined $nourlfilter) or (!defined $urlfilter));
writeFile("$path/element-filter.css",$elemfilter) unless ((defined $nocss) or (!defined $elemfilter));



sub createUrlfilter
{
  my $list = shift;
  my @urlfilter;
  my @whitelists;
  
  my $oldchecksum;
  my $oldmodified;
  
  # Get old checksum and modification time
  if (-e "$path/urlfilter.ini")
  {
    my @oldlist = (split(/\n/, (readFile("$path/urlfilter.ini"))));
    $oldchecksum = firstval { $_ =~ m/.Checksum:/ } @oldlist;
    $oldmodified = firstval { $_ =~ m/.Last modified:/ } @oldlist;
    undef @oldlist;
  }


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
          (defined $oldchecksum) ? ($line) = $oldchecksum : $line =~ s/^!/;/;
        }
        # Insert old last modified
        elsif ($line =~ m/.Last modified:/)
        {
          (defined $oldmodified) ? ($line) = $oldmodified : $line =~ s/^!/;/;
        }
        # Add the rest of comments
        unless ($line =~ m/.Redirect:/)
        {
          $line =~ s/^\!/;/;
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
          $line =~ s/^\|\|/\*:\/\//;
        }
        elsif ($line =~ m/^\|/)
        {
          $line =~ s/^\|/\*:\/\//;
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
        $line = "*".$line unless ($line =~ m/^[* ]/);
        # Add ending asterisk
        $line = $line."*" unless ($line =~ m/[* ]$/);

        push @urlfilter, $line;
      }
    }
  }


  # Return undef if list is empty
  return undef if (scalar(grep {$_ !~ m/^;/} @urlfilter) <= 0);


  $list = join("\n", @urlfilter);
  undef @urlfilter;
  my $whitelists = join("\n", @whitelists);
  my $tmpline = "";
  my $matcheswhitelist;

  foreach my $line (split(/\n/, $list))
  {
    # Remove filters that require whitelists
    ($tmpline) = $line;
    $tmpline =~ s/\*:\/\///;
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

    push @urlfilter, $line unless (defined $matcheswhitelist);
    undef $matcheswhitelist;
  }


  # Return undef if list is empty
  return undef if (scalar(grep {$_ !~ m/^;/} @urlfilter) <= 0);


  # Create rules for subdomains
  $list = join("\n", @urlfilter);
  undef @urlfilter;
  foreach my $line (split(/\n/, $list))
  {
    push @urlfilter, $line;
    if ($line =~ m/^\*\:\/\//)
    {
      $line =~ s/\*\:\/\//\*\./;
      push @urlfilter, $line;
    }
  }
  $list = join("\n", @urlfilter);

  # Add urlfilter header
  my $linenr = 0;
  foreach my $line (split(/\n/, $list))
  {
    $linenr++;
    last if ($line =~ m/^;-/);
  }
  splice (@urlfilter, $linenr, 0, "[prefs]\nprioritize excludelist=1\n[include]\n*\n[exclude]");

  return join("\n", @urlfilter);
}


sub createElemfilter
{
  my $list = shift;
  my @elemfilter;
  
  my $oldchecksum;
  my $oldmodified;

  # Get old checksum and modification time
  if (-e "$path/element-filter.css")
  {
    my @oldlist = (split(/\n/, (readFile("$path/element-filter.css"))));
    $oldchecksum = firstval { $_ =~ m/.Checksum:/ } @oldlist;
    $oldmodified = firstval { $_ =~ m/.Last modified:/ } @oldlist;
    undef @oldlist;
  }


  foreach my $line (split(/\n/, $list))
  {
    # Remove ABP header
    if ($line =~m/\[.*?\]/i)
    {
    }
    unless ($line =~ m/.Redirect:/)
    {
      if ($line =~ m/^!/)
      {
        # Insert old checksumm
        if ($line =~ m/.Checksum:/)
        {
          ($line) = $oldchecksum if defined $oldchecksum;
        }
        # Insert old last modified
        elsif ($line =~ m/.Last modified:/)
        {
          ($line) = $oldmodified if defined $oldmodified;
        }
        push @elemfilter, $line;
      }
    }

    # Add generic element filters
    if ($line =~ m/^##/)
    {
      $line =~ s/##//;
      # Convert tags to lowercase
      $line =~ s/(^.*[\[\.\#])/\L$1/ if ($line =~ m/^.*[\[\.\#]/);
      push @elemfilter, $line.",";
    }

  }


  # Return undef if list is empty
  return undef if (scalar(grep {$_ !~ m/^!/} @elemfilter) <= 0);


  # Add xml namespace declaration
  my $linenr = 0;
  $list = join("\n", @elemfilter);
  foreach my $line (split(/\n/, $list))
  {
    $linenr++;
    last if ($line =~ m/^!-/);
  }
  splice (@elemfilter, $linenr, 0, "\@namespace \"http://www.w3.org/1999/xhtml\";");

  # Remove last comma
  $elemfilter[lastidx{ ($_ =~ m/,$/) and ($_ !~ m/^!/) } @elemfilter] =~ s/,$//;

  # Add CSS rule
  push @elemfilter,"{ display: none !important; }";


  # Convert comments
  my $previousline = "";

  $list = join("\n", @elemfilter);
  undef @elemfilter;

  foreach my $line (split(/\n/, $list))
  {
    push @elemfilter, "/*" if (($previousline !~ m/^!/) and ($line =~ m/^!/));
    push @elemfilter, "*/" if (($previousline =~ m/^!/) and ($line !~ m/^!/));
    push @elemfilter, $line;
    $previousline = $line;
  }
  undef $previousline;


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