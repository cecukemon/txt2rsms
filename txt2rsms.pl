#!/usr/bin/perl

use strict;

use Getopt::Long;

my $maxchar = 25;

# Verzeichniss fuer die Ausgabe der Files
my $outdir;
# Logbuch was eingelesen und verarbeitet wird
my $infile;

GetOptions ("outdir=s" => \$outdir, "infile=s" => \$infile);

if(! $infile || ! $outdir){
  print STDOUT "Usage: ./txt2rsms.pl --infile <filename> --outdir <dirpath>\n";
  exit 0;
}

if( ! -e $infile || -z $infile){
  print STDERR "$infile ist leer oder nicht vorhanden, breche Verarbeitung ab.\n";
  exit 1;
}

if( ! -e $outdir || ! -d $outdir){
  print STDERR "$outdir ist kein Verzeichniss oder nicht vorhanden, breche Verarbeitung ab.\n";
  exit 1;
}

# das Logbuch wird hier eingelesen:
my $logbuch;

open(IN, '<', $infile);
$logbuch = join("", <IN>);
close(IN);

my @tmp = split(/(\d\d\d\d \d\d \d\d)/, $logbuch);
shift @tmp if ($tmp[0] =~ /^\s*$/);

my %logbuch = @tmp;

while(my ($date, $post) = each %logbuch){

  if($date =~ /^(\d\d\d\d) (\d\d) (\d\d)\s*$/){
    $date = make_date($1, $2, $3);
  } else {
    print STDERR "unbekanntes Datumformat $date, Eintrag wird uebersprungen.\n";
    next;
  }

  my @post = split(/\n/, $post);
  shift @post if($post[0] =~ /^\s*$/);
  my $filename = make_filename($date, make_filename_postfix($post[0]));

  next if similar_file_exists($filename);

  open(OUT, '>', $outdir.'/'.$filename);
  print OUT "---\n";
  print OUT "title: \"".$post[0]."\"\n";
  print OUT "description: \"".$post[0]." ".$post[1]." ".$post[2]."\"\n";
  print OUT "layout: post\n";
  print OUT "tags: untagged\n";
  print OUT "category: uncategorized\n";
  print OUT "comments: no\n";
  print OUT "---\n\n";
  print OUT join("\n", @post);
  close(OUT);

  print STDOUT "file $filename geschrieben\n";
}




sub make_date {
  my ($year, $mon, $day) = @_;

  return $year.'-'.$mon.'-'.$day;
}

sub make_filename_postfix {
  my ($line) = @_;

  $line =~ s/[^a-zA-Z ]//g;
  my @words = split(/ /, lc($line));

  my @tmp;

  foreach my $w (@words){
    next if($w =~ /^\s*$/);
    if(length(join('-', @tmp)) + length($w) + 1 <= $maxchar){
      push @tmp, $w;
    } else {
      last;
    }
  }

  return join('-', @tmp);
}

sub make_filename {
  my ($date, $filename_postfix) = @_;
  return $date .'-'.$filename_postfix.'.md';
}

sub similar_file_exists {
  my ($filename) = @_;

  opendir (my $dh, $outdir);
  while(readdir $dh){
    next if(! defined $_ || $_ =~ /^./);
    if($_ eq $filename && -C $outdir.'/'.$_ >= 1){
      print STDOUT "$filename existiert bereits und ist mindestens 1 Tag alt, wird uebersprungen.\n";
      return 1;
    } elsif($_ eq $filename && -C $outdir.'/'.$_ < 1){
      print STDOUT "$filename existiert bereits und ist weniger als 1 Tag alt, wird ueberschrieben.\n";
      return 0;
    }
  }
  closedir($dh);

  return 0;
}











