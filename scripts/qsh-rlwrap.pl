#!/usr/bin/env perl

# This is maybe the most practical of the filter examples. Is is also
# a test for rlwrap's signal handling.
#
# At present, a CTRL-C in a pager will also kill rlwrap (bad)

use lib ($ENV{RLWRAP_FILTERDIR} or ".");
use RlwrapFilter;
use POSIX qw(:signal_h);

# We want any piped pager to receive SIGWINCH.
# SIGWINCH is not in POSIX, which means that POSIX.pm doesn't
# know about it. We use 'kill -l' to find it.

my @signals = split /\s+/, `kill -l`; # yuck!
for (my $signo = 1; $signals[$signo-1]; $signo++) {
  if ($signals[$signo-1] eq 'WINCH') {
    my $sigset_unblock = POSIX::SigSet->new($signo);
    unless (defined sigprocmask(SIG_UNBLOCK, $sigset_unblock)) {
      die "Could not unblock signals: $!\n";
    }
  }
}

my $filter = new RlwrapFilter;
my $name = $filter->name;

$filter->help_text(<<DOC);
Usage: rlwrap -z $name <command>
Provides handling of input/output for compatibility with QSH
DOC

use constant QSH_RLWRAP_PAGER => $ENV{'QSH_RLWRAP_PAGER'};
use constant QSH_RLWRAP_CLIENT_PANE => $ENV{'QSH_RLWRAP_CLIENT_PANE'};
use constant QSH_RLWRAP_DISABLE_INITIALIZATION_MESSAGE => $ENV{'QSH_RLWRAP_DISABLE_INITIALIZATION_MESSAGE'};

use constant QSH_RESULT_REQUEST => QSH_RLWRAP_CLIENT_PANE . ".result-request";
use constant QSH_RESULT_REQUEST_COMPLETE => QSH_RESULT_REQUEST . ".complete";

my $QSH_RLWRAP_PAGER_CHECK = $ENV{'QSH_RLWRAP_PAGER_CHECK'};
if ($QSH_RLWRAP_PAGER_CHECK) {
  require "$QSH_RLWRAP_PAGER_CHECK";
}

my $initialized;
my $prompt;

my $pager = QSH_RLWRAP_PAGER;

$filter->prompts_are_never_empty(1);
$filter->input_handler(\&input);
$filter->output_handler(\&output);
$filter->prompt_handler(\&prompt);
$filter->echo_handler(\&echo);

$filter->run;

sub input {
  return $_;
}

sub output {
  return $initialized ? "" : $_;
}

sub prompt {
  $prompt = $_;
  if ($initialized) {
    my $output = $filter->cumulative_output;

    my $page = 1;
    if ($QSH_RLWRAP_PAGER_CHECK) {
      $page = QshPagerCheck::check($output);
    }

    if ($page == 1) {
      local $SIG{PIPE} = 'IGNORE'; # we don't want to die if the pipeline quits
      open PAGER, "| $pager";
      print PAGER $output;
      close PAGER; # this waits until pager has finished
    } else {
      print $output;
    }

    # Check for a result request & mark it complete if it exists
    if (-e QSH_RESULT_REQUEST) {
      open RESULT_REQUEST, ">>", QSH_RESULT_REQUEST_COMPLETE;
      close RESULT_REQUEST;
    }
  } else {
    if (-e QSH_RLWRAP_CLIENT_PANE) {
      if (!QSH_RLWRAP_DISABLE_INITIALIZATION_MESSAGE) {
        # Display a message to the user to say we are good to go
        $filter->send_output_oob("${prompt}\n");
        $filter->send_output_oob(" qsh (generic)\n");
        $filter->send_output_oob("---------------\n");
        $filter->send_output_oob("  INITIALIZED\n");
        $filter->send_output_oob("\n");
      }

      $initialized = 1;
    }
  }

  return $prompt;
}

sub echo {
  my $data = $_;
  if ($data) {
    return "${prompt}${data}";
  }

  return $data;
}

