#!perl
use strict;
use warnings;

use constant DO_WRITE => 1;

my $source = assert_repo( 'source' => shift @ARGV );
my $dest   = assert_repo( 'dest'   => shift @ARGV );

sub assert_repo {
    my ( $name, $path ) = @_;
    my ($msg) = "%s is not a valid ${name} repository ( %s )";
    die sprintf $msg, 'undef', 'must be defined'  unless defined $path;
    die sprintf $msg, '""',    'must have length' unless length $path;
    die sprintf $msg, '"' . quotemeta( $path ) . '"', 'must satisfy -d'
      unless -d $path;
    return $path;
}

require Git::Repository;

my $srepo = Git::Repository->new( work_tree => $source );
#my $drepo = Git::Repository->new( work_tree => $dest );

require Git::FastExport;
require IO::Select;
use Fcntl qw( F_GETFL F_SETFL O_NONBLOCK );

my $source_command = $srepo->command(
    qw( fast-export --use-done-feature --progress=1000 --date-order --all ));
my $source_reader = $source_command->stdout;

#my $dest_command;
my $dest_writer;

DO_WRITE and do {
  #  $dest_command =
  #    $drepo->command(qw( fast-import --depth=300 --max-pack-size=500m ));
  #$dest_writer = *STDOUT;
  open $dest_writer, '|-', 'git', '-C', $dest, qw( fast-import --depth=1 --max-pack-size=500m )
     or die "Can't spawn git-fast-import";
};

STDERR->autoflush(1);

my $parser = Git::FastExport->new( $source_reader );

my $stats = {
  blobs => 0,
  commits => 0,
  features => 0,
  resets => 0,
  dones => 0,
  m_skips => 0,
  d_skips => 0,
  c_skips => 0,
};

my $SP = q{[ ]};

my $current_branch = 'refs/heads/master';
my $branch_marks = {

};

block: while ( my $block = $parser->next_block ) {
  if ( $block->{type} eq 'blob' ) {
    $stats->{blobs}++;
    DO_WRITE and $dest_writer->print($block->as_string);
    next;
  }
  if ( $block->{type} eq 'commit' ) {
    $stats->{commits}++;
    my ( @nufiles );
    for my $file ( @{${block}->{files}} ) {
      if ( $file =~ m/\AM ${SP} (.*?) ${SP} (.*?) ${SP} (.*?) \z/x ) {
        my ( $mode, $ref, $path ) = ( $1, $2, $3 );
        # STDERR->print("mode: ${1} ref: ${2} path: \e[32m${3}\e[0m\n");
        if ( kill_path( $path ) ) {
          # STDERR->print("skipping: $file\n");
          $stats->{m_skips}++;
        } else {
          push @nufiles, $file;
        }
      } elsif ( $file =~ m/\AD ${SP} (.*?) \z/x ) {
        my ( $path ) = $1;
        if ( kill_path($path ) ) {
          # STDERR->print("skipping: $file\n");
          $stats->{d_skips}++;
        } else {
          push @nufiles, $file;
        }
      } else {
        STDERR->print("$file\n");
      }
    }
    if ( not @nufiles ) {
      # STDERR->print("empty commit: $block->{data}\n");
      $stats->{c_skips}++;
      next block;
    }
    $block->{files} = \@nufiles;
    if ( $block->{from} ) {
      $block->{from} = [];
      for my $mark (@{$branch_marks->{$current_branch}}) {
        push @{$block->{from}}, sprintf "from %s", $mark;
      }
    }
    $branch_marks->{ $current_branch } = [];
    for my $item (@{$block->{mark}}) {
      if ( $item =~ /\Amark[ ](.*)\z/ ) {
        push @{$branch_marks->{$current_branch}}, "$1";
      }
    }

    DO_WRITE and $dest_writer->print($block->as_string);
    next;
  }
  if ( $block->{type} eq 'feature' ) {
    $stats->{features}++;
    DO_WRITE and $dest_writer->print($block->as_string);
    next;
  }
  if ( $block->{type} eq 'reset' ) {
    $stats->{resets}++;
    DO_WRITE and $dest_writer->print($block->as_string);
    next;
  }
  if ( $block->{type} eq 'done' ) {
    $stats->{dones}++;
    DO_WRITE and $dest_writer->print($block->as_string);
    dumpstats();
    *STDERR->printf("\n");
    next;
  }
  if ( $block->{type} eq 'progress' ) {
    dumpstats(); 
    #  DO_WRITE and $dest_writer->print($block->as_string);
    next;
  }
  die "Unhandled type $block->{type}";

}

DO_WRITE and do {
  close $dest_writer or warn "error closing git, $?";
};

sub kill_path {
  my ( $path ) = @_;
  return 1 if $path =~ m{/files/digest\z};
  return 1 if $path =~ m{/ChangeLog\z};
  return;
}
sub dumpstats {
  *STDERR->print("\r" . join q{, }, map { sprintf "%s: %10d", $_, $stats->{$_} } sort keys %{$stats});
}


my $mark_idx = 1;

sub write_block {
  my ( $block, $fd ) = @_;


}

