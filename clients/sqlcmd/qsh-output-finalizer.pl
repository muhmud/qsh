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
my @column_counts = ();
my @column_starts = ();

my $line = "";
my $previous_line = "";

my $line_count = -1;
my $last_line_found = 0;
my $current_result = 0;

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

  if ($current_result == 0) {
    return 0;
  }

  my $max_sizes = $column_max_size[$current_result - 1];
  my $column_count = $column_counts[$current_result - 1];
  foreach my $position (@$max_sizes) {
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
  $line_count++;

  print $tmp $line;

  if ($line =~ /^([-]+[${column_separator}])*[-]+\s$/) {
    # New result set header line found
    push(@column_starts, $line_count - 1);

    my @headers = split(/[${column_separator}]+/, $previous_line);
    my @separators = split(/[${column_separator}]/, $line);

    my @min_sizes = ();
    my $index = 0;
    foreach my $header (@headers) {
      $header =~ s/^\s+|\s+$//g;
      @min_sizes[$index++] = length($header);
    }

    push(@column_min_size, [ @min_sizes ]);

    my @max_sizes = ();
    $index = 0;
    foreach my $separator (@separators) {
      $separator =~ s/^\s+|\s+$//g;
      @max_sizes[$index++] = length($separator);
    }

    push(@column_max_size, [ @max_sizes ]);

    my $column_count = scalar(@min_sizes);
    if ($column_count != scalar(@max_sizes)) {
      die "column count mismatch!";
    }
    push(@column_counts, $column_count);

    my @new_sizes = ();
    push(@column_new_size, [ @new_sizes ]);

    $current_result++;
  } elsif ($current_result > 0){
    if (is_valid_line() == 1) {
      my $index = 0;
      my $start = 0;

      my $min_sizes = @column_min_size[$current_result - 1];
      my $max_sizes = @column_max_size[$current_result - 1];
      my $new_sizes = @column_new_size[$current_result - 1];
      foreach my $size (@$max_sizes) {
        my $current_column = substr($line, $start, $size);
        $current_column =~ s/\s+$//g;
        my $current_column_length = length($current_column);        

        my $column_size = @$new_sizes[$index];
        if (!$column_size) {
          @$new_sizes[$index] = @$min_sizes[$index];
          $column_size = @$new_sizes[$index];
        }

        if ($column_size < $current_column_length) {
          @$new_sizes[$index] = $current_column_length;
        }

        $start += $size + 1;
        $index++;
      }
    }
  } 
}

close $tmp;

if ($current_result == 0) {
  copy($tmp_filename, \*STDOUT);
  exit 0;
}

open(INPUT, "<", $tmp_filename) or die $!;
$last_line_found = 0;
$line_count = -1;
$next_result_line_number = @column_starts[0];
$current_result = 0;

while(<INPUT>) {
  $previous_line = $line;
  $line = $_;
  $line_count++;

  if ($line_count == $next_result_line_number) {
    # Continue on to the next line
    next;
  }

  if ($line_count == $next_result_line_number + 1) {
    # this is a separator line
    my $index = 0;
    my $start = 0;

    my $min_sizes = @column_min_size[$current_result];
    my $max_sizes = @column_max_size[$current_result];
    my $new_sizes = @column_new_size[$current_result];
    foreach my $size (@$new_sizes) {
      my $current_column = substr($previous_line, $start, $size);

      if ($index != 0) {
        print "|";
      }
      print " $current_column ";

      $start += @$max_sizes[$index] + 1;
      $index++;
    }

    print "\n";

    $index = 0;
    $start = 0;
    foreach my $size (@$new_sizes) {
      my $current_column = substr($line, $start, $size);

      if ($index != 0) {
        print "+";
      }
      print "-$current_column-";

      $start += @$max_sizes[$index] + 1;
      $index++;
    }

    $current_result++;
    $next_result_line_number = @column_starts[$current_result];
    print "\n";
  } elsif ($current_result > 0){
    $line =~ s/\r//g;

    my $is_valid = is_valid_line();
    if ($is_valid == 1) {
      my $start = 0;
      my $index = 0;

      my $max_sizes = @column_max_size[$current_result - 1];
      my $new_sizes = @column_new_size[$current_result - 1];
      foreach my $size (@$new_sizes) {
        my $current_column = substr($line, $start, $size);

        if ($index != 0) {
          print "|";
        }
        print " $current_column ";

        $start += @$max_sizes[$index] + 1;
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
STDOUT->autoflush(1);

END {
  close $tmp;
  close INPUT;
  if (-e $tmp_filename) {
    unlink($tmp_filename);
  }
}

