#!/usr/bin/perl
use POSIX;
use Term::Cap;
use v5.14;

# This example pulled from: https://www.perlmonks.org/?node_id=1106716

# init the term
my $termios = new POSIX::Termios;
$termios->getattr;
my $ospeed = $termios->getospeed;
my $tc = Tgetent Term::Cap { TERM => undef, OSPEED => $ospeed };

# require the following capabilities
$tc->Trequire(qw/cl cd ce cm co li/);

# clear screen, clear to end of line, clear to end of screen
sub cl_scr  { $tc->Tputs('cl', 1, *STDOUT) } 
sub cl_line { $tc->Tputs('ce', 1, *STDOUT) } 
sub cl_end  { $tc->Tputs('cd', 1, *STDOUT) }

# move the cursor
sub gotoxy {
    my($x, $y) = @_;
    $tc->Tgoto('cm', $x, $y, *STDOUT);
}

sub pline {
    my ($line_no, $string) = @_;
    gotoxy(0,$line_no);
    cl_line;
    print $string;
}

my @log = map { " > " } (0..9);

# redraw the log
sub flush_log {
    my $i = 0;
    for my $logline (@log) {
        pline ($i, $logline);
        $i++;
    }
    pline ($i, "==================================================");
    gotoxy(0,++$i);
    cl_end;
}

# print line to log
sub plog {
    my $line = shift;
    shift @log;
    push @log, " > $line";
    flush_log;
}

my $correct = 42;
my $number;
my $choice;

flush_log;

do {
    print "What is the correct number: ";
    chomp($number = <STDIN>);

    if ($number == $correct) {
        plog "Game result: WIN";
        say "Good answer. Play again? (y/n)";
        chomp($choice = <STDIN>);
    }
    else {
        plog "Game result: LOSE";
        say "Bad answer. Play again? (y/n)";
        chomp($choice = <STDIN>);
    }
} while ($choice eq 'y');

