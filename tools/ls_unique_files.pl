#!perl
use strict;
use warnings;

my $repo = shift @ARGV;

die "Please specify a path to a repo to traverse" unless defined $repo;

my $target = shift @ARGV;

die "Please specify a path to an output file" unless defined $target;

open my $ofh, ">", $target or die "Can't open $target, $?";

$ENV{TZ} = 'UTC';

my $format = '';

$format .= "H:%H\n";                   # Commit hash
$format .= "P:%P\n";                   # Parent hashes
$format .= "an:%an\n";                 # Author Name
$format .= "ae:%ae\n";                 # Author email
$format .= "ad:%ad\n";                 # Author date
$format .= "cn:%cn\n";                 # Committer name
$format .= "ce:%ce\n";                 # Committer email
$format .= "cd:%cd\n";                 # Committer date
$format .= "s:%s\n";                   # Subject
$format .= "b:----\n%B\n/b:----\n";    # Body

my $dateformat = '%s %z';              # Seconds since epoch + user timezone

open my $fh, '-|', 'git', '--no-pager', '-C', $repo, 'log',
  '-z',
  '--format=format:' . $format,
  '--raw',
  '--no-abbrev',
  '--no-renames', '--reverse', '--date=format:' . $dateformat, @ARGV,
  or die "Can't spawn git";

binmode $fh, ":utf8";

local $/ = "\0\0";

my $seen = {};

*STDERR->autoflush(1);
while ( my $record = <$fh> ) {
    chomp $record;

    my ( $hash, $parents, $an, $ae, $ad, $cn, $ce, $cd, $s, $b, $rest ) =
      $record =~ m{
      \A
      H:(.*?)\n
      P:(.*?)\n
      an:(.*?)\n
      ae:(.*?)\n
      ad:(.*?)\n
      cn:(.*?)\n
      ce:(.*?)\n
      cd:(.*?)\n
      s:(.*?)\n
      b:----\n(.*?)\n/b:----\n\n
      (.*)
    \z
    }xgms;

    die "can't parse $record" if not defined $hash;

    #printf "\e[33mcommit\e[0m %s\n", $hash;
    #printf "\e[33mparents\e[0m %s\n", $parents;
    #printf "\e[33mauthor\e[0m %s (%s) %s\n", $an, $ae, $ad;
    #printf "\e[33mcommitter\e[0m %s (%s) %s\n", $cn, $ce, $cd;
    #printf "\e[33msubject\e[0m %s\n", $s;
    #printf "\e[33mbody:\e[0m\n%s\n", $b;

    my (@fpairs) = split /\0/, $rest;
    my (@files);
    my $changed = 0;
    while (@fpairs) {
        my ( $data, $file ) = splice @fpairs, 0, 2, ();
        next if exists $seen->{$file};
        printf "%s\n", $file;
        $ofh->printf( "%s\0", $file );
        if ( not $changed ) {
            *STDERR->printf( "\e[32m%s\e[0m\n",
                ( scalar localtime [ split / /, $cd ]->[0] ) );
        }
        $changed++;
        $seen->{$file}++;
    }
    if ( not $changed ) {
        *STDERR->printf("\e[31m.\e[0m");
    }

}
