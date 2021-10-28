package QshPagerCheck;
our @EXPORT_OK = qw( check );

sub check {
  my $output = $_[0];

  my $initial = substr($output, 0, 1024);
  if ($initial =~ /<RESULTS>/) {
    return 1;
  }

  return 0;
}

