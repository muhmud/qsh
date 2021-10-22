#!/usr/bin/perl

use File::Temp qw/ tempfile tempdir /;
use File::Copy;

($tmp, $tmp_filename) = tempfile();

my $column_separator = $ENV{'QSH_PAGER_PREPROCESSOR_COLUMN_SEPARATOR'};
if (!$column_separator) {
  $column_separator = "|";
}

my @column_min_size = ();
my @column_max_size = ();
my @column_new_size = ();
my $column_count = 0;

my $line = "";
my $previous_line = "";

my $headers_initialized = 0;
my $output_started = 0;
my $last_line_found = 0;

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

  if ($headers_initialized == 0) {
    if ($line =~ /^([-]+[${column_separator}])*[-]+\s$/) {
      my @headers = split(/[${column_separator}]+/, $previous_line);
      my @separators = split(/[${column_separator}]/, $line);

      my $index = 0;
      foreach my $header (@headers) {
        $header =~ s/^\s+|\s+$//g;
        @column_min_size[$index++] = length($header);
      }

      $index = 0;
      foreach my $separator (@separators) {
        $separator =~ s/^\s+|\s+$//g;
        @column_max_size[$index++] = length($separator);
      }

      $column_count = scalar @column_min_size;
      if ($column_count != scalar(@column_max_size)) {
        die "column count mismatch!";
      }

      $headers_initialized = 1;
    }
  } else {
    if (is_valid_line() == 1) {
      my $index = 0;
      my $start = 0;
      foreach my $size (@column_max_size) {
        my $current_column = substr($line, $start, $size);
        $current_column =~ s/\s+$//g;
        my $current_column_length = length($current_column);        

        my $column_size = $column_new_size[$index];
        if (!$column_size) {
          $column_new_size[$index] = $column_min_size[$index];
          $column_size = $column_new_size[$index];
        }

        if (!$column_size || $column_size < $current_column_length) {
          $column_new_size[$index] = $current_column_length;
        }

        $start += $size + 1;
        $index++;
      }
    }
  } 
}

close $tmp;

if ($headers_initialized == 0) {
  copy($tmp_filename, \*STDOUT);
  exit 0;
}

open(INPUT, "<", $tmp_filename) or die $!;
$last_line_found = 0;

while(<INPUT>) {
  $previous_line = $line;
  $line = $_;

  if ($output_started == 0) {
    if ($line =~ /^([-]+[${column_separator}])*[-]+\s$/) {
      my $index = 0;
      my $start = 0;
      foreach my $size (@column_new_size) {
        my $current_column = substr($previous_line, $start, $size);

        if ($index != 0) {
          print "|";
        }
        print " $current_column ";

        $start += $column_max_size[$index] + 1;
        $index++;
      }

      print "\n";

      $index = 0;
      $start = 0;
      foreach my $size (@column_new_size) {
        my $current_column = substr($line, $start, $size);

        if ($index != 0) {
          print "+";
        }
        print "-$current_column-";

        $start += $column_max_size[$index] + 1;
        $index++;
      }

      print "\n";
      $output_started = 1;
    } 
  } else {
    $line =~ s/\r//g;

    my $is_valid = is_valid_line();
    if ($is_valid == 1) {
      my $start = 0;
      my $index = 0;
      foreach my $size (@column_new_size) {
        my $current_column = substr($line, $start, $size);

        if ($index != 0) {
          print "|";
        }
        print " $current_column ";

        $start += $column_max_size[$index] + 1;
        $index++;
      }

      print "\n";
    } else {
      if ($is_valid == -1) {
        print $line;
        last;
      }

      print "$line\n";
    }
  }
}

close INPUT;

END {
  close $tmp;
  close INPUT;
  if (-e $tmp_filename) {
    unlink($tmp_filename);
  }
}

