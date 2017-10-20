#!perl
use strict;
use warnings;

use HTTP::Tiny;
use JSON::MaybeXS;
use Data::Dump qw(pp);

my $ua      = HTTP::Tiny->new();
my $decoder = JSON::MaybeXS->new();

my $dist = $ARGV[0] or die "Pass a dist-name dummy";

my $result =
  $ua->get( 'https://fastapi.metacpan.org/v1/release?q=distribution:'
      . $dist
      . '&fields=download_url,maturity,status,authorized,date&size=500' );

if ( not $result->{success} ) {
    die "can't fetch history for $dist: $result->{status} $result->{reason}\n";
}
my $content = $decoder->decode( $result->{content} )->{hits}->{hits};

for my $record ( sort { $a->{fields}->{date} cmp $b->{fields}->{date} }
    @{$content} )
{
    my $rec = $record->{fields};
    printf "%s %s\n", $rec->{date}, $rec->{download_url};
}
