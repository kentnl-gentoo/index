#!perl
use strict;
use warnings;

my %commits = (
  '3cc88bf03f314ff19bf3be103c718ffcef9b9e56' => '2015-05-02 14:39',
  '08359b7bd6798dc4365962a7881b2db8b7108cf0' => '2015-07-16 12:48',
  '8a69e794cd3526bc879c5374d8c294302fe242d8' => '2016-01-27 18:15',
  '42146b1f6cd1468db6d89306c6e2eb1f7d06de6a' => '2016-09-17 02:33',
  '85b2046c0314e07ff6f504719ff0442184c07ccb' => '2017-06-23 23:50',
);

if ( $ENV{'GIT_COMMIT'} and exists $commits{$ENV{'GIT_COMMIT'}} ) {
  printf "export GIT_AUTHOR_DATE=\"%s\"\nexport GIT_COMITTER_DATE=\"%s\"\n",
    ( $commits{$ENV{GIT_COMMIT}} ) x 2;
}
