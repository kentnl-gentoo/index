#!perl
use strict;
use warnings;

use constant SET_AUTHOR    => 0;
use constant SET_COMMITTER => 1;
use constant NAME          => 'Justin Lecher';
use constant EMAIL         => 'jlec@gentoo.org';

my %commits = (
  '3cc88bf03f314ff19bf3be103c718ffcef9b9e56' => '2015-05-02 14:39',
  '08359b7bd6798dc4365962a7881b2db8b7108cf0' => '2015-07-16 12:48',
  '8a69e794cd3526bc879c5374d8c294302fe242d8' => '2016-01-27 18:15',
  '42146b1f6cd1468db6d89306c6e2eb1f7d06de6a' => '2016-09-17 02:33',
  '85b2046c0314e07ff6f504719ff0442184c07ccb' => '2017-06-23 23:50',
);

if ( $ENV{'GIT_COMMIT'} and exists $commits{ $ENV{'GIT_COMMIT'} } ) {

    my $commit_date = $commits{ $ENV{'GIT_COMMIT'} };

    if (SET_AUTHOR) {
        printf "export GIT_AUTHOR_DATE=\"%s\"\n",  $commit_date;
        printf "export GIT_AUTHOR_NAME=\"%s\"\n",  NAME;
        printf "export GIT_AUTHOR_EMAIL=\"%s\"\n", EMAIL;
    }
    if (SET_COMMITTER) {
        printf "export GIT_COMMITTER_DATE=\"%s\"\n",  $commit_date;
        printf "export GIT_COMMITTER_NAME=\"%s\"\n",  NAME;
        printf "export GIT_COMMITTER_EMAIL=\"%s\"\n", EMAIL;
    }
}

=pod

=head1 USAGE

=over 4

=item 1. Find your SHA1

=item 2. Find a tarball for it

=item 3. Extract a timestamp

  TZ=UTC tar -vtf Acme-Data-Dumper-Extensions-0.001000.tar.gz |\
         cut -c 32-47 |\
         sort -u |\
         tail -n 1

=item 4. Add an entry as above

=item 5. filter the branch

  git filter-branch --env-filter 'eval $(perl /tmp/index/tools/filters/datefix.pl)' releases 7.13-gentoo

=item 6. Keep in mind, this affects all refs reachable from commitishes.

If you want to do only one side of the graph, do a range like:

  commitx..commity

Where "commitx" is the last commit on the right, and commity is the first-parent side.

Make sure you read git-filter branch for that shit.

=back
