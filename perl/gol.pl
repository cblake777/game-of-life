#!/usr/bin/perl

use strict;
use warnings;
use v5.30;

use POSIX;
use Term::Cap;
use Data::Dumper;
use Time::HiRes;
use Getopt::Long;

# Each cell has 8 neighbors:
#    * * * o o o
#    * X * o o o
#    * * * o o o
#    o o o o o o
#    o o o o o o
# but if those neighbors are at the edges, it has to wrap
#    X * o o o *
#    * * o o o *
#    o o o o o o
#    o o o o o o
#    * * o o o *


my %opts;

GetOptions(\%opts, 'rows=i','cols=i');
my $rows = $opts{rows} || 5;
my $cols = $opts{cols} || 5;

# init the term
my $termios = new POSIX::Termios;
$termios->getattr;
my $ospeed = $termios->getospeed;
my $tc = Tgetent Term::Cap { TERM => undef, OSPEED => $ospeed };

my @cells;

initGrid();

sub initGrid {
	cls();
	my $seed = time();

	pline(0, "Conway's Game of Life -- seed: $seed, rows: $rows, cols: $cols");

	my $rowCount = 1;
	my $columnCount = 0;
	for (my $i = 0; $i < $rows * $cols; $i++) {

		my $state = rand(($seed*($i+1))) % 3.14159 ? 'alive' : 'dead';

		$columnCount++;
		if ($columnCount > $cols) {
			$rowCount++;
			$columnCount = 1;
		}

		# say "Row: $rowCount -- Col: $columnCount";
		my @neighborDefs = (
			[-1, -1], [-1, 0], [-1, 1],
			[ 0, -1],          [ 0, 1],
			[ 1, -1], [ 1, 0], [ 1, 1],
		);

		my @neighbors;
		foreach my $nDef (@neighborDefs) {
			my $nRow = $rowCount + $nDef->[0];
			$nRow = $rows if $nRow < 1;
			$nRow = 1 if $nRow > $rows;

			my $nCol = $columnCount + $nDef->[1];
			$nCol = $cols if $nCol < 1;
			$nCol = 1 if $nCol > $cols;

			my $nIndex = (($nRow-1) * $cols + ($nCol-1));
			# say "ni: $nRow, $nCol, $nIndex";
			push @neighbors, $nIndex;
		}
		# say "nindex: " . join(", ", @neighbors);

		push @cells, {
			index => $i,
			state => $state,
			row   => $rowCount,
			col   => $columnCount,
			neighbors => \@neighbors,
		};
	}

	renderGrid();
	processRows();
}

sub renderGrid {
	foreach my $row (1..$rows) {
		my $cellStart = ($row-1)*$cols;
		my $cellEnd = $cellStart+$cols-1;

		my @lineCells = @cells[$cellStart..$cellEnd];

		my $line = join '  ', map { cellCharacter($_) } @lineCells;
		pline($row, $line);
	}
	clEnd();
}

sub processRows {
	my $processRow = 0;
	while (1) {
		$processRow = 0 if $processRow >= $rows;

		my $cellStart = ($processRow)*$cols;
		my $cellEnd = $cellStart+$cols-1;

		my @lineCells = @cells[$cellStart..$cellEnd];

		foreach my $cell (@lineCells) {
			my $index = $cell->{index};

			# this is just for debug testing.
			#$cell->{state} = 'flux';

			my $liveNeighbors = grep { $cells[$_]->{state} eq 'alive' } @{$cell->{neighbors}};
			my $deadNeighbors = grep { $cells[$_]->{state} eq 'dead' } @{$cell->{neighbors}};

			if ($cell->{state} eq 'dead' && $liveNeighbors == 3) {
				$cell->{state} = 'alive';
			}
			elsif ($cell->{state} eq 'alive' && ($liveNeighbors < 2 || $liveNeighbors > 3)) {
				$cell->{state} = 'dead';
			}
		}

		my $line = join '  ', map { cellCharacter($_) } @lineCells;

		pline($processRow+1, $line);
		$processRow++;
		Time::HiRes::sleep(.1);
	}

	return;
}

sub cellCharacter {
	my $cell = shift;
	return $cell->{state} eq 'alive'    ? 'X'
		 : $cell->{state} eq 'flux'     ? '*'
		 : $cell->{state} eq 'neighbor' ? '~'
		 : 'º';
}

sub pline {
	my ($line_no, $string) = @_;
	gotoXY(0, $line_no);
	clLine();
	say $string;
}

# move the cursor
sub gotoXY {
	my($x, $y) = @_;
	$tc->Tgoto('cm', $x, $y, *STDOUT);
}

# clear screen, clear to end of line, clear to end of screen
sub cls  { $tc->Tputs('cl', 1, *STDOUT) }
sub clLine { $tc->Tputs('ce', 1, *STDOUT) }
sub clEnd  { $tc->Tputs('cd', 1, *STDOUT) }
