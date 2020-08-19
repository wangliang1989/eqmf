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
my $threshold = 15;
match ($tempdir, $workdir);

sub match {
    my ($tempdir, $workdir) = @_;
    my ($id) = (split m/\//, $tempdir)[-1];
    my $num = 0;
    my $corfile = " ";
    my ($evlo, $evla, $evdp, $kztime, $kzdate);
    unlink glob "$workdir/*.cor";
    foreach (glob "$tempdir/*.[enz]") {
        my ($file) = (split m/\//, $_)[-1];
        next unless (-e "$workdir/$file");
        (undef, $evlo, $evla, $evdp) = split m/\s+/, `saclst evlo evla evdp f $_`;
        (undef, $kzdate, $kztime) = split m/\s+/, `saclst kzdate kztime f $workdir/$file`;
        system "eqcor $workdir/$file $_ $workdir/${id}-${file}.cor";
        $num++;
        $corfile = "$corfile $workdir/${id}-${file}.cor";
        open(SAC, "| sac") or die "Error in opening sac\n";
        print SAC "wild echo off \n";
        print SAC "cuterr fillz\n";
        print SAC "cut 0 86400\n";
        print SAC "r $workdir/${id}-${file}.cor\n";
        print SAC "w over\n";
        print SAC "q\n";
        close(SAC);
    }
    sum("$workdir/result_${id}.txt", $kzdate, $kztime, $evlo, $evla, $evdp, $num, $corfile) if ($num > 0);
}
sub sum {
    my ($result, $kzdate, $kztime, $evlo, $evla, $evdp, $num, $corfile) = @_;
    my @info = split m/\n/, `eqsum $threshold $num $corfile`;
    open (OUT, "> $result") or die;
    foreach (@info) {
        my ($time, $cc, $mad, $th) = (split m/\s+/)[1..4];
        print OUT "$kzdate $kztime $time $evlo $evla $evdp $mad $th $cc\n";
    }
    close (OUT);
    my @to_delete = split m/\s+/, $corfile;
    unlink @to_delete;
}
