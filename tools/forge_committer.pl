#!perl
use strict;
use warnings;

my $authors   = {};
my $email_idx = {};
my $name_idx  = {};

sub add_author {
    my ( $nick, $name, $email ) = @_;
    die "nick $nick already exists" if exists $authors->{$nick};
    die "email <$email> for $nick already exists in set"
      if exists $email_idx->{$email};
    die "name <$name> for $nick already exists in set"
      if exists $name_idx->{$name};
    $authors->{$nick}    = { name => $name, email => $email };
    $email_idx->{$email} = $authors->{$nick};
    $name_idx->{$name}   = $authors->{$nick};
}

sub add_gauthor {
    my ( $nick, $name ) = @_;
    add_author( $nick, $name, $nick . '@gentoo.org' );
}

sub add_cauthor {
    my ( $nick, $name ) = @_;
    add_author( $nick, $name, $nick . '@cpan.org' );
}

sub add_dauthor {
    my ( $nick, $name ) = @_;
    add_author( $nick, $name, $nick . '@debian.org' );
}

sub add_authors {
    my (@items) = @_;

    while (@items) {
        my ( $nick, $entry ) = splice @items, 0, 2, ();
        if ( not exists $entry->{name} ) {
            die "entry for $nick lacks name";
        }
        if ( not exists $entry->{email} ) {
            die "entry for $nick lacks email";
        }
        my ($email) = $entry->{email};
        my ($name)  = $entry->{name};
        add_author( $nick, $entry->{name}, $entry->{email} );
    }
}

sub query_author {
    my ($id) = @_;
    return $authors->{$id} if exists $authors->{$id};
    if ( $id =~ /\@/ ) {
        return $email_idx->{$id} if exists $email_idx->{$id};
        die "Unknown email $id";
    }
    die "Unknown author $id";
}

add_author( 'bhenry'      => 'Brock Henry' => 'brock.henry@gmail.com' );
add_author( 'fabio rossi' => "Fabio Rossi" => 'rossi.f@inwind.it' );
add_author(
    'mguen' => 'Michael Guennewig' => 'guennewi@ls6.cs.uni-dortmund.de' );
add_author( 'mjb'       => 'Mike Beattie'     => 'mjb@debian.org' );
add_author( 'morten'    => 'Morten Bøgeskov' => 'morten@bogeskov.dk' );
add_author( 'thilbrich' => 'Torsten Hilbrich' => 'Torsten.Hilbrich@gmx.net' );

# CPAN
add_cauthor( 'jdhedden' => 'Jerry D. Hedden' );
add_cauthor( 'jkeenan'  => 'James E Keenan' );

# Debian
add_dauthor( 'dmn'     => 'Damyan Ivanov' );
add_dauthor( 'jaldhar' => 'Jaldar H. Vyas' );

# Gentoo
add_gauthor( 'achim'       => 'Achim Gottinger' );
add_gauthor( 'agriffis'    => 'Aron Griffis' );
add_gauthor( 'aliz'        => 'Daniel Ahlberg' );
add_gauthor( 'avenj'       => 'Jon Portnoy' );
add_gauthor( 'azarah'      => 'Martin Schlemmer' );
add_gauthor( 'bjb'         => 'Bjoern Brauel' );
add_gauthor( 'blizzy'      => 'Maik Schreiber' );
add_gauthor( 'brad_mssw'   => 'Brad House' );
add_gauthor( 'cardoe'      => 'Doug Goldstein' );
add_gauthor( 'chainsaw'    => 'Tony Vroon' );
add_gauthor( 'ciaranm'     => 'Ciaran McCreesh' );
add_gauthor( 'corsair'     => 'Markus Rothe' );
add_gauthor( 'cselkirk'    => 'Calum Selkirk' );
add_gauthor( 'danarmak'    => 'Dan Armak' );
add_gauthor( 'darkspecter' => 'Bartosch Pixa' );
add_gauthor( 'dev-zero'    => 'Tiziano Müller' );
add_gauthor( 'dilfridge'   => "Andreas K. Hüttel" );
add_gauthor( 'drobbins'    => 'Daniel Robbins' );
add_gauthor( 'eradicator'  => 'Jeremy Huddleston' );
add_gauthor( 'gbevin'      => 'Geert Bevin' );
add_gauthor( 'gerk'        => 'Mark Guertin' );
add_gauthor( 'gmsoft'      => 'Guy Martin' );
add_gauthor( 'gustavoz'    => 'Gustavo Zacarias' );
add_gauthor( 'hardave'     => "Hardave Rior" );
add_gauthor( 'herbs'       => "Herbie Hopkins" );
add_gauthor( 'iggy'        => 'Brian Jackson' );
add_gauthor( 'jrray'       => 'J Robert Ray' );
add_gauthor( 'kentnl'      => "Kent Fredric" );
add_gauthor( 'kloeri'      => "Bryan Østergaard" );
add_gauthor( 'kugelfang'   => 'Danny van Dyk' );
add_gauthor( 'kumba'       => "Joshua Kinard" );
add_gauthor( 'liquidx'     => "Alastair Tse" );
add_gauthor( 'lostlogic'   => "Brandon Low" );
add_gauthor( 'lu_zero'     => "Luca Barbato" );
add_gauthor( 'lv'          => "Travis Tilley" );
add_gauthor( 'manson'      => "Rodney Rees" );
add_gauthor( 'mcummings'   => "Michael Cummings" );
add_gauthor( 'mholzer'     => "Martin Holzer" );
add_gauthor( 'monsieurp'   => "Patrice Clement" );
add_gauthor( 'mr_bones_'   => "Michael Sterrett" );
add_gauthor( 'murphy'      => 'Maarten Thibaut' );
add_gauthor( 'patrick'     => "Patrick Lauer" );
add_gauthor( 'pete'        => 'Peter Gavin' );
add_gauthor( 'prez'        => 'Preston A. Elder' );
add_gauthor( 'pvdabeel'    => "Pieter van den Abeele" );
add_gauthor( 'rac'         => "Robert Coie" );
add_gauthor( 'radhermit'   => 'Tim Harder' );
add_gauthor( 'randy'       => 'Michael McCabe' );
add_gauthor( 'sandymac'    => 'William McArthur' );
add_gauthor( 'seemant'     => 'Seemant Kulleen' );
add_gauthor( 'solar'       => 'Ned Ludd' );
add_gauthor( 'spider'      => 'D.M.D. Ljungmark' );
add_gauthor( 'squinky86'   => 'Jon Hood' );
add_gauthor( 'taviso'      => "Tavis Ormandy" );
add_gauthor( 'tester'      => "Olivier Crête" );
add_gauthor( 'todd'        => 'Todd Sunderlin' );
add_gauthor( 'tove'        => "Torsten Veller" );
add_gauthor( 'tuxus'       => "Jan Seidel" );
add_gauthor( 'vapier'      => "Mike Frysinger" );
add_gauthor( 'woodchip'    => 'Donny Davies' );
add_gauthor( 'zlogene'     => "Mikle Kolyada" );
add_gauthor( 'zwelch'      => "Zack Welch" );

my $fake_env = { TZ => 'UTC', };

for my $arg ( @ARGV ) {
  if ( $arg !~ /\A--(author=.*|ts=.*|commit(=.*|)|commit-ts=.*)\z/ ) {
    die "Unknown arg $arg"
  }
}

for my $arg ( @ARGV ) {
  if ( $arg =~ /\A--author=(.*)\z/ ) {
    my $entry = query_author($1);
    $fake_env->{GIT_AUTHOR_NAME}  = $entry->{name};
    $fake_env->{GIT_AUTHOR_EMAIL} = $entry->{email};
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
      my $entry = query_author($1);
      $fake_env->{GIT_COMMITTER_NAME}  = $entry->{name};
      $fake_env->{GIT_COMMITTER_EMAIL} = $entry->{email};
      $fake_env->{GIT_COMMITTER_DATE}  = $fake_env->{GIT_AUTHOR_DATE}
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
