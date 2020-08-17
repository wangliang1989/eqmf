#!/usr/bin/env perl
use strict;
use warnings;
use Parallel::ForkManager;
use List::Util qw(min max);
use Time::HiRes qw(gettimeofday tv_interval);
use FindBin;
use lib $FindBin::Bin;
#require config;
$ENV{SAC_DISPLAY_COPYRIGHT}=0;

my ($tempdir, $workdir) = @ARGV;
my $threshold = 10;
match ($tempdir, $workdir);

sub match {
    my ($tempdir, $workdir) = @_;
    my ($id) = (split m/\//, $tempdir)[-1];
    my $num = 0;
    my $corfile = " ";
    my ($b, $e, $evlo, $evla, $evdp, $kztime, $kzdate);
    foreach (glob "$tempdir/*.BH?") {
        my ($file) = (split m/\//, $_)[-1];
        next unless (-e "$workdir/$file");
        (undef, $evlo, $evla, $evdp) = split m/\s+/, `saclst evlo evla evdp f $_`;
        (undef, $kzdate, $kztime) = split m/\s+/, `saclst kzdate kztime f $workdir/$file`;
        my (undef, $bi, $ei) = split m/\s+/, `eqcor $workdir/$file $_ $workdir/${id}-${file}.cor`;
        $b = $bi unless (defined($b));
        $e = $ei unless (defined($e));
        $b = min($b, $bi);
        $e = max($e, $ei);
        $num++;
        $corfile = "$corfile $workdir/${id}-${file}.cor";
    }
    sum($id, $kzdate, $kztime, $evlo, $evla, $evdp, $b, $e, $num, $corfile) if ($num > 0);
}
sub sum {
    my ($id, $kzdate, $kztime, $evlo, $evla, $evdp, $b, $e, $num, $corfile) = @_;
    open(SAC, "| sac") or die "Error in opening sac\n";
    print SAC "wild echo off \n";
    print SAC "cuterr fillz\n";
    print SAC "cut $b $e\n";
    print SAC "r $corfile\n";
    print SAC "write over\n";
    print SAC "q\n";
    close(SAC);
    my @info = split m/\n/, `eqsum $threshold $num $corfile`;
    open (OUT, "> result_$id.txt") or die;
    foreach (@info) {
        my ($time, $cc, $mad, $th) = (split m/\s+/)[1..4];
        print OUT "$kzdate $kztime $time $evlo $evla $evdp $mad $th $cc\n";
        print "$kzdate $kztime $time $evlo $evla $evdp $mad $th $cc\n";
    }
    close (OUT);
}
