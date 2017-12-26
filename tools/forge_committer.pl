#!perl
use strict;
use warnings;

my $authors = {
  'tove' => {
    name => "Torsten Veller",
    email => 'tove@gentoo.org'
  },
  'patrick' => {
    name => "Patrick Lauer",
    email => 'patrick@gentoo.org',
  },
  'radhermit' => {
    name => 'Tim Harder',
    email => 'radhermit@gentoo.org',
  },
  'zlogene' => {
    name => "Mikle Kolyada",
    email => 'zlogene@gentoo.org',
  },
  'dilfridge' => {
    name => 'Andreas K. Hüttel',
    email => 'dilfridge@gentoo.org',
  },
  'kentnl' => {
    name => "Kent Fredric",
    email => 'kentnl@gentoo.org',
  },
};

my $fake_env = {};

for my $arg ( @ARGV ) {
  if ( $arg !~ /\A--(author=.*|ts=.*|commit(=.*|)|commit-ts=.*)\z/ ) {
    die "Unknown arg $arg"
  }
}

for my $arg ( @ARGV ) {
  if ( $arg =~ /\A--author=([^ ]+)\z/ ) {
    my ( $aid ) = $1;
    if ( not exists $authors->{$aid} ) {
      die "Unknown author $aid";
    }
    $fake_env->{GIT_AUTHOR_NAME} = $authors->{$aid}->{name};
    $fake_env->{GIT_AUTHOR_EMAIL} = $authors->{$aid}->{email};
    next;
  }
}
for my $arg ( @ARGV ) {
  if( $arg =~ /\A--ts=(.*)\z/ ) {
    $fake_env->{GIT_AUTHOR_DATE} = $1;
    next;
  }
}
if ( not exists $fake_env->{GIT_AUTHOR_NAME} ) {
  die "need an author to fake";
}
for my $arg ( @ARGV ) {
  if ( $arg =~ /\A--commit\z/ ) {
    $fake_env->{GIT_COMMITTER_NAME} = $fake_env->{GIT_AUTHOR_NAME};
    $fake_env->{GIT_COMMITTER_EMAIL} = $fake_env->{GIT_AUTHOR_EMAIL};
    $fake_env->{GIT_COMMITTER_DATE} = $fake_env->{GIT_AUTHOR_DATE} 
      if exists $fake_env->{GIT_AUTHOR_DATE};
  }
}

for my $key ( sort keys %{$fake_env} ) {
  printf "export %s=\'%s\'\n", $key, $fake_env->{$key};
}
