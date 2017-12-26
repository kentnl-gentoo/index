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
  'monsieurp' => {
    name => "Patrice Clement",
    email => 'monsieurp@gentoo.org',
  },
  'dev-zero' => {
    name => 'Tiziano Müller',
    email => 'dev-zero@gentoo.org',
  },
  'fabio rossi' => {
    name => "Fabio Rossi",
    email => 'rossi.f@inwind.it',
  },
  'chainsaw' => {
    name => 'Tony Vroon',
    email => 'chainsaw@gentoo.org',
  },
  'dmn' => {
    name => 'Damyan Ivanov',
    email => 'dmn@debian.org',
  },
  'mguen' => {
    name => 'Michael Guennewig',
    email => 'guennewi@ls6.cs.uni-dortmund.de',
  },
  'jaldhar' => {
    name => 'Jaldar H. Vyas',
    email => 'jaldhar@debian.org',
  },
  'morten' => {
    name => 'Morten Bøgeskov',
    email => 'morten@bogeskov.dk',
  },
  'thilbrich' => {
    name => 'Torsten Hilbrich',
    email => 'Torsten.Hilbrich@gmx.net',
  },
  'mjb' => {
    name => 'Mike Beattie',
    email => 'mjb@debian.org',
  },
  'bhenry' => {
    name => 'Brock Henry',
    email => 'brock.henry@gmail.com',
  },
  'jkeenan' => {
    name => 'James E Keenan',
    email => 'jkeenan@cpan.org',
  }
};

my $fake_env = {};

for my $arg ( @ARGV ) {
  if ( $arg !~ /\A--(author=.*|ts=.*|commit(=.*|)|commit-ts=.*)\z/ ) {
    die "Unknown arg $arg"
  }
}

for my $arg ( @ARGV ) {
  if ( $arg =~ /\A--author=(.*)\z/ ) {
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
  if ( $arg =~ /\A--commit=(.*)\z/ ) {
      my $cid = $1;
      if ( not exists $authors->{$cid} ) {
        die "Unknown committer $cid";
      }
      $fake_env->{GIT_COMMITTER_NAME} = $authors->{$cid}->{name};
      $fake_env->{GIT_COMMITTER_EMAIL} = $authors->{$cid}->{email};
      $fake_env->{GIT_COMMITTER_DATE} = $fake_env->{GIT_AUTHOR_DATE}
        if exists $fake_env->{GIT_AUTHOR_DATE};
  }
}
for my $arg ( @ARGV ) {
  if( $arg =~ /\A--commit-ts=(.*)\z/ ) {
    $fake_env->{GIT_COMMITTER_DATE} = $1;
    next;
  }
}

for my $key ( sort keys %{$fake_env} ) {
  printf "export %s=\'%s\'\n", $key, $fake_env->{$key};
}
