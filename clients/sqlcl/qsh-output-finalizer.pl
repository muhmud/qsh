#!/usr/bin/perl

use XML::SAX::ParserFactory;
use XML::SAX::PurePerl;

use File::Temp qw/ tempfile tempdir /;
use File::Copy;

($tmp, $tmp_filename) = tempfile();

my @columns = ();
my @column_max_sizes = ();

my $first_column == "";
my $in_column_element;
my $column_name;
my $column_number = 0;

my $factory = new XML::SAX::ParserFactory;
my $handler = new XML::SAX::PurePerl;

my $xml_found = 0;
my $end_found = 0;
my $trailing_info = "";

while(<>) {
  $line = $_;

  if ($line =~ /<\?xml version='1.0'  encoding='UTF-8' \?>/) {
    next;
  }

  if ($line =~ /<RESULTS>/) {
    print $tmp $line;
    $xml_found = 1;
  } elsif ($end_found == 1) {
    $trailing_info=$trailing_info . $line . "\n";
  } else {
    my $cleaned_line = $line =~ s/\r|\s//rg;
    if ($cleaned_line ne "") {
      print $tmp $line;
    }

    if ($line =~ /<\/RESULTS>/) {
      $end_found = 1;
    }
  }
}

close $tmp;

if ($xml_found == 0) {
  copy($tmp_filename, \*STDOUT);
  exit 0;
}

my $parser = $factory->parser(
    Handler => $handler,
    Methods => {
        start_element => sub {
          my $element = $_[0];
          my $element_name = $element->{LocalName};
          if ($element_name eq "COLUMN") {
            $column_name = $element->{Attributes}->{"{}NAME"}->{Value};
            $in_column_element = 1;

            if (scalar(@columns) == $column_number) {
              @columns[$column_number] = $column_name;
            }
          } elsif ($element_name eq "ROW") {
            $column_number = 0;
          }
        },

        end_element => sub {
          if ($in_column_element == 1) {
            $in_column_element = 0;
            $column_number++;
          }
        },

        characters => sub {
          if ($in_column_element == 1) {
            my $value = $_[0];
            my $data = $value->{Data};

            my $column_max_size = $column_max_sizes[$column_number];
            if (!$column_max_size) {
              $column_max_size = length($columns[$column_number]);
              @column_max_sizes[$column_number] = $column_max_size;
            }

            my $column_size = length($data);
            if ($column_size > $column_max_size) {
              @column_max_sizes[$column_number] = $column_size;
            }
          }
        }
    }
);

$parser->parse_uri($tmp_filename);
print "\n";

my $column_count = scalar(@columns);
my $index = 0;
foreach my $column (@columns) {
  my $size = @column_max_sizes[$index++];
  my $spaces = " " x ($size - length($column));

  print " $column$spaces ";
  if ($index != $column_count) {
    print "|";
  }
}

print "\n";

$index = 0;
foreach my $column (@columns) {
  my $size = @column_max_sizes[$index++];
  my $dashes = "-" x $size;

  print "-$dashes-";
  if ($index != $column_count) {
    print "+";
  }
}

print "\n";

my $in_row_element = 0;
$column_number = 0;

my $parser = $factory->parser(
    Handler => $handler,
    Methods => {
        start_element => sub {
          my $element = $_[0];
          my $element_name = $element->{LocalName};
          if ($element_name eq "COLUMN") {
            $in_column_element = 1;
          } elsif ($element_name eq "ROW") {
            $in_row_element = 1;
            $column_number = 0;
          }
        },

        end_element => sub {
          my $element = $_[0];
          my $element_name = $element->{LocalName};

          if ($element_name eq "COLUMN") {
            $in_column_element = 0;
            $column_number++;
          } elsif ($element_name eq "ROW"){
            $in_row_element = 0;
          } 
        },

        characters => sub {
          if ($in_column_element == 1) {
            my $value = $_[0];
            my $data = $value->{Data};

            my $size = $column_max_sizes[$column_number];
            my $spaces = " " x ($size - length($data));
            print " $data$spaces ";

            if ($column_number + 1 != $column_count) {
              print "|";
            } else {
              print "\n";
            }
          }
        }
    }
);

$parser->parse_uri($tmp_filename);

if ($trailing_info ne "") {
  print "\n$trailing_info";
}

END {
  close $tmp;
  if (-e $tmp_filename) {
    unlink($tmp_filename);
  }
}

