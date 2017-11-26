#!perl
use strict;
use warnings;

use Path::Tiny qw( path );

use constant mydir => path($0)->absolute->parent;

my @import_list = path( $ARGV[0] )->lines_raw( { chomp => 1 } );

system( 'git', 'checkout', '-b', 'releases' );
{
    my $line = shift @import_list;
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
    my $line = shift @import_list;
    my ( $commit, @parents ) = split qr/\s+/, $line;
    if ( $commit =~ /\A\d\d\d\d-\d\d-\d\dT/ ) {
      $commit = shift @parents;
    }
    if ( not @parents ) {
        system( $^X, path( mydir, 'urlimport.pl' ), $commit );
    }
    else {
        local $ENV{EXTRA_PARENT} = join q[ ], @parents;
        system( $^X, path( mydir, 'urlimport.pl' ), $commit );
    }
}

