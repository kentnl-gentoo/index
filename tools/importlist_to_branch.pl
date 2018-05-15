#!perl
use strict;
use warnings;

use Path::Tiny qw( path );

use constant mydir => path($0)->absolute->parent;

my @import_list = path( $ARGV[0] )->lines_raw( { chomp => 1 } );

my $steps = 0;
my $steps_skipped = 0;


system( 'git', 'checkout', '-b', 'releases' );
{
    my $line = shift @import_list;
    if ( $ENV{STEP_SKIP} and $ENV{STEP_SKIP} > 0 ) {
      while( $steps_skipped < $ENV{STEP_SKIP} ) {
        warn "\e[32mSkipped:\e[0m $line\n";
        $line = shift @import_list;
        $steps_skipped++;
      }
    }
    my ( $commit, @parents ) = split qr/\s+/, $line;
    if ( $commit =~ /\A\d\d\d\d-\d\d-\d\dT/ ) {
      $commit = shift @parents;
    }
    if ( not @parents ) {
        local $ENV{NO_PARENTS} = 1;
        system( $^X, path( mydir, 'urlimport.pl' ), $commit );
    }
    else {
        local $ENV{NO_PARENTS} = 1;
        local $ENV{EXTRA_PARENT} = join q[ ], @parents;
        system( $^X, path( mydir, 'urlimport.pl' ), $commit );
    }
}
while (@import_list) {
    $steps++;
    last if exists $ENV{STEP_LIMIT} and $ENV{STEP_LIMIT} < $steps;
    my $line = shift @import_list;
    my ( $commit, @parents ) = split qr/\s+/, $line;
    if ( $commit =~ /\A\d\d\d\d-\d\d-\d\dT/ ) {
      $commit = shift @parents;
    }
    next if exists $ENV{STEP_SKIP} and $ENV{STEP_SKIP} <= $steps;
    if ( not @parents ) {
        system( $^X, path( mydir, 'urlimport.pl' ), $commit );
    }
    else {
        local $ENV{EXTRA_PARENT} = join q[ ], @parents;
        system( $^X, path( mydir, 'urlimport.pl' ), $commit );
    }
}

