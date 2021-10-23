#!/usr/bin/perl

use File::Temp qw/ tempfile tempdir /;
use File::Copy;

($tmp, $tmp_filename) = tempfile();

my $column_separator = $ENV{'QSH_PAGER_PREPROCESSOR_COLUMN_SEPARATOR'};
if (!$column_separator) {
  $column_separator = "|";
}

my $line = "";
my $previous_line = "";
my $first_column_length = 0;
my $headers_found = 0;
my $last_line_found = 0;
my $blank_line_count = 0;

sub is_valid_line {
  my $is_valid = 1;
  my $index = 0;
  my $start = 0;

  if ($line =~ /^\([0-9]+ rows affected\)$/) {
    $last_line_found = 1;
    return -1;
  }

  if ($last_line_found == 1) {
    return 0;
  }

  foreach my $position (@column_max_size) {
    if (++$index != $column_count) {
      if ($start == 0) {
        $start = $position;
      } else {
        $start += $position + 1;
      }
      if (substr($line, $start, 1) ne $column_separator) {
        $is_valid = 0;
        last;
      }
    }
  }

  return $is_valid;
}

while(<>) {
  $previous_line = $line;
  $line = $_;

  print $tmp $line;

  if ($headers_found == 0) {
    if ($line =~ /^([-]+[${column_separator}])*[-]+\s$/) {
      my @separators = split(/[${column_separator}]/, $line);
      my $separator = $separators[0];
      $separator =~ s/^\s+|\s+$//g;
      $first_column_length = length($separator);
      $headers_found = 1;
    }
  } else {
    $line =~ s/\r//g;

    my $is_valid = is_valid_line();
    if ($is_valid == 1) {
      my $first_column = substr($line, 0, $first_column_length);
      $first_column =~ s/\s+$//g;

      if ($first_column eq "") {
        $blank_line_count++;
      } else {
        if ($blank_line_count > 0) {
          for my $i (1..$blank_line_count) {
            print "\n";
          }

          $blank_line_count = 0;
        }

        print "$first_column\n";
      }
    } elsif ($is_valid == -1) {
      last;
    }
  }
}

close $tmp;

if ($headers_found == 0) {
  copy($tmp_filename, \*STDOUT);
  exit 0;
}

END {
  close $tmp;
  if (-e $tmp_filename) {
    unlink($tmp_filename);
  }
}

