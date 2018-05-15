#!perl
use strict;
use warnings;

my ( $repo, $destrepo, $filterfile, ) = splice @ARGV, 0, 3, ();

use File::Spec;
my $self = File::Spec->rel2abs($0);

if ( not defined $repo or not length $repo or not -d $repo ) {
    $repo = "\"$repo\""   if defined $repo and length $repo;
    $repo = '(undefined)' if not defined $repo;
    $repo = '""'          if not length $repo;
    STDERR->print("\e[31;40;1m$repo\e[0m is not a valid repository dir\n");
    die "No valid repository";
}
if ( not defined $destrepo or not length $destrepo or not -d $destrepo ) {
    $destrepo = "\"$destrepo\"" if defined $destrepo and length $destrepo;
    $destrepo = '(undefined)'   if not defined $destrepo;
    $destrepo = '""'            if not length $destrepo;
    STDERR->print("\e[31;40;1m$destrepo\e[0m is not a valid repository dir\n");
    die "No valid dest repository";
}

if ( not defined $filterfile or not length $filterfile or not -r $filterfile ) {
    $filterfile = "\"$filterfile\""
      if defined $filterfile and length $filterfile;
    $filterfile = '(undefined)' if not defined $filterfile;
    $filterfile = '""'          if not length $filterfile;
    STDERR->print("\e[31;40;1m$filterfile\e[0m is not a valid filter file\n");
    die "No valid filter file";
}

my (%whitelist);
{
    local $/ = "\n";
    open my $fh, '<', $filterfile or die "Can't read filterfile";
    while ( my $file = <$fh> ) {
        chomp $file;
        $whitelist{$file} = 1;
    }
}

STDERR->print("\e[31;40;1m **** ACHTUNG!!!!! ****\e[0m\n");
STDERR->print("\n");
STDERR->print("\e[31;40m This is a potentially destructive action\e[0m\n");
STDERR->print(
    "\e[31;40m and should be performed on a clone of the repository\e[0m\n");
STDERR->print("\n");
STDERR->print("\e[32;1mSource Repository:\e[0m $repo\n");
STDERR->print("\e[32;1mTarget Repository:\e[0m $destrepo\n");
STDERR->print("\e[32;1mFilter File:\e[0m $filterfile\n");
STDERR->print("\e[32;1mDriver Script:\e[0m $self\n");
STDERR->print("\n");
STDERR->autoflush(1);
STDERR->print("\e[31;401m Continuing in: \e[0m");
my $backpad    = "";
my $sleep_size = 0.01;
my $timelimit  = 2;

while ( $timelimit >= 0 ) {
    STDERR->printf( "\e[33;40;1m%s%5.2f \e[0m", $backpad, $timelimit );
    $backpad = "\b" x ( ( length sprintf "%5.2f", $timelimit ) + 1 );
    $timelimit -= $sleep_size;
    select( undef, undef, undef, $sleep_size );
}
STDERR->print("\n");
chdir $repo or die "Can't enter $repo, $?";

open my $export, '-|', 'git', 'fast-export', '--progress', 10_000, @ARGV
  or die "Can't start git-fast-export";

my $state = {};
my $backbuf;
my $cmd = "";

open my $import, '|-', 'git','-C',$destrepo, 'fast-import' or die "Can't start git-fast-import";

#open my $import, '>' , '/dev/null' or die "Can't open target";
#my $import = \*STDOUT;

while ( my $cmd = get_cmd($export) ) {
    my ( $cmd, $args ) = @{ $cmd };
    if ( $cmd eq 'blob' ) {
      cp_blob( $export, $import );
      next;
    }
    if ( $cmd eq 'reset' ) {
      cp_reset( $export, $import, $args );
      next;
    }
    if ( $cmd eq 'commit' ) {
      cp_commit( $export, $import, $args );
      next;
    }
    if ( $cmd eq 'progress' ) {
      cp_progress( $export, $import, $args );
      next;
    }
    die "Unhandled $cmd->[0]";
}

close $export or die "Error closing git-fast-export, $?";
close $import or die "Error closing git-fast-import, $?";

*STDERR->print("Now might be a good time to run:\n");
*STDERR->print(" git repack --window=300 --window-memory=4G -A -d -f  --max-pack-size=500m --unpack-unreachable=now");
*STDERR->print(" git prune --expire=now --verbose");
*STDERR->print(" git filter-branch --prune-empty master\n");

my (@cmd_buf) = @_;
sub unget_cmd {
    push @cmd_buf, $_[0];
}
sub get_cmd {
    my ($in) = @_;
    if ( @cmd_buf ) {
      return shift @cmd_buf;
    }
    local $/ = "\n";
    my $line = <$in>;
    return unless defined $line;
    chomp $line;
    if ( $line =~ /\A(\S+)\z/ ) {
        return ["$1"];
    }
    if ( $line =~ /\A(\S+)\s(.*)\z/ ) {
        return [ "$1", "$2" ];
    }
    if ( $line eq "" ) {
        return get_cmd($in);
    }
    die "Unparsed line: $line";
}

sub cp_data {
    my ( $in, $out, $size ) = @_;
    $out->printf("data %s\n", $size);
    while ( $size > 0 ) {
        my $bytes_read = read $in, my $buf, ( $size > 8192 ? 8192 : $size );
        die "Can't read" unless defined $bytes_read;
        $out->print($buf);
        $size -= $bytes_read;
    }
    $out->printf("\n");
}

sub cp_blob {
    my ( $in, $out ) = @_;
    $out->print("blob\n");
    while(1) {
      if ( my $cmd = get_cmd($in) ) {
        if ( $cmd->[0] eq 'mark' ) {
          cp_mark( $in, $out, $cmd->[1] );
          next;
        }
        if ( $cmd->[0] eq 'data' ) {
          cp_data( $in, $out, $cmd->[1] );
          return;
        }
        die "Unknown cmd in blob: $cmd->[1], expected mark or data";
      }
      die "EOF parsing blob";
    }
}
sub cp_reset {
  my ($in, $out, $args ) = @_;
  $out->printf("reset %s\n",  $args || '');
  my $cmd = get_cmd( $in );
  if ( $cmd and $cmd->[0] eq 'from' ) {
    $out->printf("from %s\n", $cmd->[1]);  
  } else {
    unget_cmd($cmd);
  }
}
sub cp_progress {
  my ($in, $out, $args ) = @_;
  $out->printf("progress %s\n",  $args || '');
  *STDERR->printf("\e[31m.\e[0m");
}

my %backrefs;

sub cp_commit {
  my ($in, $out, $args ) = @_;
  $out->printf("commit %s\n",  $args || '');
  my $cmd = get_cmd( $in );
  if ( $cmd and $cmd->[0] eq 'mark' ) {
    cp_mark( $in, $out, $cmd->[1] );
    $cmd = get_cmd( $in );
  }
  if ( $cmd and $cmd->[0] eq 'author' ) {
    cp_author( $in, $out, $cmd->[1] );
    $cmd = get_cmd( $in );
  }
  if ( $cmd and $cmd->[0] eq 'committer' ) {
    cp_committer( $in, $out, $cmd->[1] );
    $cmd = get_cmd( $in );
  } else {
    defined $cmd or die "EOF while looking for committer in commit to $args";
    die "Unexpected command $cmd in commit, expected committer";
  }
  if ( $cmd and $cmd->[0] eq 'data' ) {
    cp_data( $in, $out, $cmd->[1] );
    $cmd = get_cmd( $in );
  } else {
    defined $cmd or die "EOF while looking for data in commit $args";
    die "Unexpected command $cmd in commit, expected data";
  }
  if ( $cmd and $cmd->[0] eq 'from' ) {
    $out->printf("from %s\n", $cmd->[1]);
    $cmd = get_cmd($in);
  }
  if ( $cmd and $cmd->[0] eq 'merge' ) {
    $out->printf("merge %s\n", $cmd->[1]);
    $cmd = get_cmd($in);
  }
  while ( $cmd ) {

    # N SP DATAREF SP COMMITISH
    if ( $cmd->[0] eq 'N' ) {
      $out->printf("N %s\n", $cmd->[1]);
      if ( $cmd->[1] =~ /\Ainline / ) {
        $cmd = get_cmd($in);
        if ( $cmd->[0] ne 'data' ) {
          die "Missing 'data' while parsing inline Note, got $cmd->[0] instead";
        }
        cp_data( $in, $out, $cmd->[1]);
      }
      $cmd = get_cmd($in);
      next;
    }
    # M SP MODE    SP DATAREF SP PATH
    if ( $cmd->[0] eq 'M' ) {
      my ( $mode, $dataref, $path ) = $cmd->[1] =~ /\A(\S+)\s(\S+)\s(.*)\z/;
      if ( not exists $whitelist{$path} and $dataref ne 'inline' ) {
        # STDERR->printf("\e[33mign\e[0m M %s\n", $path);
        STDERR->print("\e[33m-\e[0m");
        $backrefs{$path} = [ $mode, $dataref, $path ];
        $cmd = get_cmd($in);
        next;
      }
      #STDERR->print("\e[32m+\e[0m");
      STDERR->printf("\e[32m+++\e[0m M %s\n", $path);
      $out->printf("M %s\n", $cmd->[1]);
      if ( $cmd->[1] =~ /\A\S+\sinline\s/ ) {
        $cmd = get_cmd($in);
        if ( $cmd->[0] ne 'data' ) {
          die "Missing 'data' while parsing inline Modify, got $cmd->[0] instead";
        }
        cp_data($in,$out, $cmd->[1]);
      }
      $cmd = get_cmd($in);
      next;
    }
    if ( $cmd->[0] eq 'D' ) {
      if ( exists $whitelist{$cmd->[1]} ) {
        $out->printf("%s %s\n", $cmd->[0], $cmd->[1] );
        STDERR->print("\e[32m-\e[0m");
      } else {
        # STDERR->printf("\e[33mign\e[0m D %s\n", $cmd->[1]);
        STDERR->print("\e[32m-\e[0m");
        delete $backrefs{$cmd->[1]};
      }
      $cmd = get_cmd($in);
      next;
    }
    if ( $cmd->[0] =~ /\A(C|R)\z/ ) {
      my ( $src, $dest ) = $cmd->[1] =~ /\A(.*?)\s(\S+)\z/;
      if ( exists $whitelist{$dest} and exists $whitelist{$src} ) {
        STDERR->printf("\e[32m+++\e[0m %s %s\n", $cmd->[0], $cmd->[1]);
        #STDERR->print("\e[32m>\e[0m");
        $out->printf("%s %s\n", $cmd->[0], $cmd->[1] );
        $cmd = get_cmd($in);
        next;
      }
      if ( exists $whitelist{$dest} and exists $backrefs{$src}  ) {
        STDERR->printf("\e[35m+ %s => %s\e[0m", $backrefs{$src}[1], $dest );
        # STDERR->printf("\e[32m+++\e[0m \e[35m^\e[0m %s\n", $dest);
        $out->printf("M %s %s %s", $backrefs{$src}{0}, $backrefs{$src}[1], $dest );
        $cmd = get_cmd($in);
        next;
      }
      if ( not exists $whitelist{$dest} and exists $whitelist{$src} ) {
        STDERR->print("\e[35m-\e[0m");
        #
        #        STDERR->printf("\e[32m---\e[0m \e[35mvv\e[0m %s\n", $dest);
        #        STDERR->printf("\e[33mign\e[0m %s %s\n", $cmd->[0], $cmd->[1]);
        $out->printf("D %s\n", $src);
        $cmd = get_cmd($in);
        next;
      }
      STDERR->print("\e[33m~\e[0m");
      # STDERR->printf("\e[33mign\e[0m %s<> %s\n", $cmd->[0], $cmd->[1]);
      $cmd = get_cmd($in);
      next;
      # noop :)
    }
    if ( $cmd eq 'deleteall' ) {
      $out->printf("deleteall\n");
      $cmd = get_cmd($in);
      next;
    }
    # End of commit
    $out->print("\n");
    unget_cmd( $cmd );
    return;
  }
  return;
}

sub cp_mark {
  my ( $in, $out, $value ) = @_;
  $out->printf("mark %s\n", $value);
}
sub cp_author {
  my ( $in, $out, $value ) = @_;
  $out->printf("author %s\n", $value );
}
sub cp_committer {
  my ( $in, $out, $value ) = @_;
  $out->printf("committer %s\n", $value );
}
