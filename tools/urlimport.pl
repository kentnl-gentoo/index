#!perl
use strict;
use warnings;
use feature 'say';

my $url = $ARGV[0] || die "Give URL to fetch";

use HTTP::Tiny; 
use Path::Tiny qw( path );
use CPAN::DistnameInfo;

my $wd; 
BEGIN {
  $wd = path('/tmp/urlimport_dir');
  $wd->mkpath;
}

my $ua; 
BEGIN {
  $ua = HTTP::Tiny->new();
}

my ($tname,) = ( $url =~ qr{/([^/]+)\z} );

my ($tfile) = $wd->child($tname);
say "$url => $tfile";
if ( $url =~ /^http/  ) {
  my $response = $ua->mirror( $url, $tfile );
  if ( not $response->{success} ) {
    die "Could not fetch $url: $response->{status} $response->{reason}";
  }
} else {
  if ( not $tfile->is_file ) {
    die "$tfile is unfetchable, please create it manually";
  }
}

$ENV{TZ} = "UTC";

## Get timestap
{
  if ( $tfile->basename =~ /\.zip/ ) {
    open my $fh, '-|', 'zipinfo','--t','--h','-T', $tfile->stringify or die "Can't run infozip $tname";
    my %seen_timestamps;
    while ( my $line = <$fh> ) {
      chomp $line;
      # mode, version, whatver, size, type, othertype 
      $line =~ s/\A(\S+\s+){6}//;
      my ( $timestamp, ) = ($line =~ qr{\A(\S+\.\S+)});
      $seen_timestamps{$timestamp}++;
    }
    my ( $oldest, ) = reverse sort keys %seen_timestamps;
    my ( $yyyy, $mm, $dd, $hh, $min, $ss ) = ( $oldest =~ /\A(....)(..)(..)\.(..)(..)(..)/ );
    $oldest = "${yyyy}-${mm}-${dd} ${hh}\:${min}\:${ss}";
    say "Timestamp: $oldest";
    $ENV{GIT_COMMITTER_DATE} = $oldest;
    $ENV{GIT_AUTHOR_DATE} = $oldest;

  } else {
    open my $fh, '-|', 'tar', '--full-time','--utc','--numeric-owner','-vtf', $tfile->stringify or die "Can't untar $tname";
    my %seen_timestamps;
    while ( my $line = <$fh> ) {
      chomp $line;
      $line =~ s/\A\S+\s\S+\s//;
      $line =~ s/\A\s*\d+\s//;
      my ( $timestamp, ) = ($line =~ qr{\A(\S+\s*\S+)});
      $seen_timestamps{$timestamp}++;
    }
    my ( $oldest, ) = reverse sort keys %seen_timestamps;
    say "Timestamp: $oldest";
    $ENV{GIT_COMMITTER_DATE} = $oldest;
    $ENV{GIT_AUTHOR_DATE} = $oldest;
  }
}
if ( path('.gitignore')->exists ) {
  system('git', 'rm', '.gitignore');
}
# Nuke existing files
{
  open my $fh, '-|', 'git', 'ls-files','-z' or die "Can't spawn ls-files";
  local $/ = qq{\0};
  my ( @buf );
  while ( my $filename = <$fh> ) {
    chomp $filename;
    push @buf, $filename;
    # say "\e[31m$filename\e[0m";
    if (( 1000 < length join q[ ], @buf )  or @buf > 1000 ) {
      system('git','rm', '-q', '-f', @buf ) == 0 or die "Can't delete!";
      @buf = ();
    }
  }
  if( @buf ) {
      system('git','rm', '-q','-f', @buf ) == 0 or die "Can't delete!";
      @buf = ();
  }
}

if ( $tfile->basename =~ /\.zip/ ) {
  system('unzip','--D', $tfile->stringify,'-x','.git/*','-d','.') == 0 or die "Zip bailed";
} else {
  # Unroll new tar
  {
    system('tar','--transform=s/^\.\///','--strip-components=1', '--exclude=.git/*', '-xf', $tfile->stringify ) == 0 or die "Tar bailed";
  }
}
# Add new files
{
  system('git', 'add', '.' ) == 0 or die "Can't add!";
}

my $info = CPAN::DistnameInfo->new($url);

my $tree;
{
  open my $fh, '-|', 'git', 'write-tree' or die "Write tree failed";
  local $/ = undef;
  $tree = scalar <$fh>;
  $tree =~ s/\s*\z//m;
  close $fh or die "Write tree failed";
}
say "tree SHA1 is $tree";
my $commit;
{
  $ENV{GIT_AUTHOR_NAME} = $info->cpanid || 'Unknown';
  $ENV{GIT_AUTHOR_EMAIL} = defined $info->cpanid ? ( lc($info->cpanid) . '@cpan.org' ) : 'unknown@example.org';
  $ENV{GIT_COMMITTER_NAME} = 'Kent Fredric';
  $ENV{GIT_COMMITTER_EMAIL} = 'kentnl@cpan.org';

  my $mesg = "Import $url";

  my (@parents);
  if ( not $ENV{NO_PARENTS} ) {
    push @parents, '-p','HEAD'
  };
  if ( $ENV{EXTRA_PARENT} ) {
    for my $parent ( split /\s+/, $ENV{EXTRA_PARENT} ) {
      push @parents, '-p', $parent;
    }
  }
  open my $fh, '-|', 'git','commit-tree', $tree, '-m', $mesg, @parents;
  local $/ = undef;
  $commit = scalar <$fh>;
  $commit =~ s/\s*\z//m;
  close $fh or die "Commit tree failed";
}
say "commit SHA1 is $commit";
system("git","update-ref","-m", "Adding $url", "HEAD", $commit) == 0 or die "Can't update-ref";

__END__

=pod

=encoding UTF-8

=head1 NAME

urlimport - Import a tarball from a CPAN Url and stuff it in git

=head1 VERSION

version 0.1

=head1 USAGE

=over 4

=item 1. Be in a CPAN distro fork

=item 2. Be on a releases branch

=item 3. have a version URL

    perl /tmp/index/tools/urlimport.pl https://cpan.metacpan.org/YADAYADA.tar.gz

=item 4. If you're an adult:

    EXTRA_PARENT="$sha1" perl /tmp/index/tools/urlimport.pl https://cpan.metacpan.org/YADAYADA.tar.gz

=item 5. PS: This has my name all over it atm and will forge commits weirdly, but nobody cares, its mostly to have *SOME* record so I can keep my sanity intact.

=back

=cut
