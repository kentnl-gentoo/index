#!perl
use strict;
use warnings;

my ( $repo, $filterfile, ) = splice @ARGV,0, 2, ();

use File::Spec;
use Cwd qw( realpath );
my $self = File::Spec->rel2abs($0);
my $helper = realpath( $self . '/../filter_index_helper.pl' );

if ( not defined $repo or not length $repo or not -d $repo ) {
  $repo = "\"$repo\"" if defined $repo and length $repo;
  $repo = '(undefined)' if not defined $repo;
  $repo = '""' if not length $repo;
  STDERR->print("\e[31;40;1m$repo\e[0m is not a valid repository dir\n");
  die "No valid repository";
}
if ( not defined $filterfile or not length $filterfile or not -r $filterfile ) {
  $filterfile = "\"$filterfile\"" if defined $filterfile and length $filterfile;
  $filterfile = '(undefined)' if not defined $filterfile;
  $filterfile = '""' if not length $filterfile;
  STDERR->print("\e[31;40;1m$filterfile\e[0m is not a valid filter file\n");
  die "No valid filter file";
}
STDERR->print("\e[31;40;1m **** ACHTUNG!!!!! ****\e[0m\n");
STDERR->print("\n");
STDERR->print("\e[31;40m This is a potentially destructive action\e[0m\n");
STDERR->print("\e[31;40m and should be performed on a clone of the repository\e[0m\n");
STDERR->print("\n");
STDERR->print("\e[32;1mTarget Repository:\e[0m $repo\n");
STDERR->print("\e[32;1mFilter File:\e[0m $filterfile\n");
STDERR->print("\e[32;1mDriver Script:\e[0m $self\n");
STDERR->print("\e[32;1mHelper Script:\e[0m $helper\n");
STDERR->print("\n");
STDERR->autoflush(1);
STDERR->print("\e[31;401m Continuing in: \e[0m");
my $backpad = "";
my $sleep_size = 0.01;
my $timelimit = 2;
while( $timelimit >= 0 ) { 
  STDERR->printf("\e[33;40;1m%s%5.2f \e[0m", $backpad, $timelimit);
  $backpad = "\b" x (( length sprintf "%5.2f", $timelimit ) + 1);
  $timelimit -= $sleep_size;
  select(undef,undef,undef,$sleep_size);
}
STDERR->print("\n");
chdir $repo or die "Can't enter $repo, $?";
$ENV{filterfile} = $filterfile;
system('git', 'filter-branch', '--index-filter', 'perl ' . $helper );
