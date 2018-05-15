#!perl
use strict;
use warnings;

my ( $filterfile, ) = splice @ARGV, 0, 1, ();

if ( $ENV{filterfile} ) {
  $filterfile = $ENV{filterfile};
}

my ( %whitelist );
my ( %fastlist );
my ( %nuked );
{
  local $/ = "\n";
  open my $fh, '<', $filterfile or die "Can't read filterfile";
  while ( my $file = <$fh> ) {
    chomp $file;
    $whitelist{$file} = 1;   
    my $toptoken  = $file;
    $toptoken =~ s{/.*\z}{};
    $fastlist{$toptoken} = 1;
  }
}
STDOUT->autoflush(1);
STDOUT->print("\n");
# Optimization:
#
# This code is heavily engineered to 
# 1. Minimise the number of calls to "git rm"
# 2. Maximise the effectiveness of each call to "git rm"
#
# This is done by:
# 1. Identifying entire directories that can be safely culled by using
#    path roots as identifiers and relying on git to recursively remove them
# 2. Clustering all parameters to git in as large a line as possible
#    while still staying within the system limits for total ARGV size.
#    ( Currently hardcoded at roughly 16k characters )
#
# This is because each call to "git rm" is expensive in multiple ways, there's
# the syscall overhead, of course, but also performance considerations within
# git itself.
#
# After each call to "git rm", git must recalculate the resulting SHA1's of any
# affected trees, and recursively modify their parents and recalculate their
# SHA1s. This is not cheap.
#
# Subsequently, performing as many as possible changes in a single removal
# (and importantly, culling trees in such a way that they never have to be
# computed) helps substantially to avoid IO and SHA1 taxes.
#
# Each call to "git rm" is indicated in the output markers with a bold, red, "C"
# 
# Deleted trees are marked by "/" in the output
# Deleted files are marked by "." (or "*" if they're special) in the output
# Kept files are marked by "+" in the output.
{
  my @files;
  { 
    local $/ = "\0";
    open my $fh, '-|', 'git', 'ls-files', '-z' or die "Can't invoke git-ls-files";
    @files = <$fh>;
    chomp for @files;
  }
  my (@delete);
  for my $file ( grep /\//, @files ) {
    my $toptoken  = $file;
    $toptoken =~ s{/.*\z}{};
    if ( not exists $fastlist{$toptoken} ) {
      next if exists $nuked{$toptoken};
      $nuked{$toptoken} = 1;
      print "\e[31m/\e[0m";
      push @delete,$toptoken;
      next;
    }
  }
  while ( @files ) {
    my $file = shift @files;
    my $toptoken  = $file;
    $toptoken =~ s{/.*\z}{};
    next if exists $nuked{$toptoken};
    if ( not exists $whitelist{$file} ) {
      if ( $file =~ m{(Manifest|digest-[^/]+|metadata\.xml)\z} ) {
        print "\e[35m*\e[0m";
      } else {
        print "\e[31m.\e[0m";
      }
      push(@delete, $file );
      next;
    }
    print "\e[32m+\e[0m";
  }
  while(@delete) {
    my @buf;
    while( ( length join "\n", @buf ) < 16_000 and @delete ) {
      push @buf, shift @delete;
    }
    system("git","rm","-r", "--cached",'-q','--', @buf ) == 0 or die "nuke lower token failed";
    print "\e[31;1mC\e[0m";
  }
}
