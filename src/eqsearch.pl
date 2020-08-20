#!/usr/bin/env perl
use strict;
use warnings;
use Parallel::ForkManager;
use List::Util qw(min max);
use Time::HiRes qw(gettimeofday tv_interval);
#use FindBin;
#use lib $FindBin::Bin;
$ENV{SAC_DISPLAY_COPYRIGHT}=0;

my $threshold = 15;
foreach my $workdir (@ARGV) {
    die "no $workdir" unless (-d $workdir);
    foreach my $tempdir (glob "template/*"){
        match ($tempdir, $workdir) if (-d $tempdir);
        last;
    }
}

sub match {
    my ($tempdir, $workdir) = @_;
    my ($id) = (split m/\//, $tempdir)[-1];
    my $num = 0;
    my $corfile = " ";
    my ($evlo, $evla, $evdp, $kztime, $kzdate);
    unlink glob "$workdir/*.cor";
    foreach (glob "$tempdir/*") {
        my ($tempfile) = (split m/\//, $_)[-1];
        #3J_BLHC.z.P
        my ($sta, $q) = split m/\./, $tempfile;
        my $file = "${sta}.${q}";
        next unless (-e "$workdir/$file");
        (undef, $evlo, $evla, $evdp) = split m/\s+/, `saclst evlo evla evdp f $_` unless (defined($evlo));
        (undef, $kzdate, $kztime) = split m/\s+/, `saclst kzdate kztime f $workdir/$file` unless (defined($kzdate));
        system "eqcor $workdir/$file $_ $workdir/${id}_${file}.cor";
        $num++;
        $corfile = "$corfile $workdir/${id}_${file}.cor";
        fillz ("$workdir/${id}_${file}.cor");
    }
    sum("result/${id}_${workdir}.txt", $kzdate, $kztime, $evlo, $evla, $evdp, $num, $corfile) if ($num > 0);
}
sub fillz {
    my ($file) = @_;
    open(SAC, "| sac") or die "Error in opening sac\n";
    print SAC "wild echo off \n";
    print SAC "cuterr fillz\n";
    print SAC "cut 0 86400\n";
    print SAC "r $file\n";
    print SAC "w over\n";
    print SAC "q\n";
    close(SAC);
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
