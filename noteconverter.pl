#!/usr/bin/perl
#--------------------#
# 
# Script name: noteconverter.pl
# 
#   
if(($ARGV[0])&&($ARGV[1])){
  $format = $ARGV[0]; chomp $format;
  $srcdir = $ARGV[1]; chomp $HMTL;
  SWITCH: for ($format) {
    /plain/i && do {$ext="txt";};
    /latex/i && do {$ext="tex";};
    /epub/i  && do {$ext="epub";};
    /json/i  && do {$ext="json";};
    /org/i   && do {$ext="org";};
    /docx/i  && do {$ext="docx";};
    /gfm|markdown|markdown_mmd/i && do {$ext="md";};
  }
}else{
print<<JKP;
USAGE:  
noteconverter.pl -h : Show this help message
noteconverter.pl <format> <HTMLDIR> : Converts the HTML files located at HTMLDIR into the specified pandoc format

Attachments, images, pdf's etc are saved to a resources directory and linked from the exported note.

Current formats supported: plain latex epub json org docx gfm markdown markdown_mmd

JKP
exit;
}

# Test for pandoc
chomp($pandoc=`which pandoc`);

if ($pandoc eq ""){
  print("This tool requires an installed copy of pandoc (https://pandoc.org)\n\n");
  exit;
}

print("Source:\t\t$srcdir\nFormat:\t\t$format\nExtension:\t$ext\n");

if(!-d $srcdir){print("\n\nError: Cannot find exported files at $srcdir!\n\nPlease specify the correct folder location for the HTML export\n");exit;}
$srcatt = ".resources";
$outdir = $format;
if(!-d $outdir){system("mkdir $outdir");}


@files = `ls $srcdir/*.html`;
foreach $src (@files){
  chomp $src;
  $attach_found = 0;
  print("\n\n---\nProcessing $src...\n");

  $attachdir = $src;
  $attachdir =~ s/\.html$//g;
  $attachdir = $attachdir.$srcatt;
  #$attachdir =~ s/(\W)/\\$1/g;
  $output = $src; 

  $output    =~ s/\.html$//g;
  $output    =~ s/^?\ //;
  $output    =~ s/\ /_/g;
  $output    =~ s/\W//g;
  print("OUT: $output\n");

  $output    =~ s/^HTML/$outdir\//;  
  $outfile = $output.".".$ext;

  print("\nSource:\t\t\t$src\nAttachement Location:\t$attachdir\nOutfile:\t\t$outfile\nOut Attached:\t\t$output\n\n");


  #---
  # Convert the file from html to plaintext
  #---
  print("$pandoc $src -f html -t $format -s -o $outfile\n");
  system("$pandoc \"$src\" -f html -t $format -s -o $outfile");
  


  #---
  # If there's a directory, we need to process the files included
  #---
  print("Checking for attachments in $attachdir\n");
  if(-d $attachdir){
    $attach_found = 1;
    print("\tmkdir -p $output\n");
    system("mkdir -p $output");

    @attachments = `ls "$attachdir"`;
    foreach $a (@attachments){
      chomp $a;
      $afile = $attachdir."/".$a;
      ($foo,$bar,$new_a) = split('/', $afile);
      $new_a =~ s/\ /_/g;

      print ("\tcp $afile $output/\n");
      system ("cp \"$afile\" $output/");
    }
  }else{
    print("No attachment directory found ($attachdir)\n\n");
    $attach_found = 0;
  }


  # Now need to open the md and rewrite any URL to match the new directory...
  #if(scalar @attachments > 0){
  if($attach_found > 0){
    open(FILE, ">>$outfile")||die "Cannot open $file: $!\n";
      print FILE ("\n---\n### Attachments ###\n");
      foreach $a (@attachments){
        $afile = $attachdir."/".$a;
        ($foo,$bar,$new_a) = split('/', $afile);
        $output=~s/^$outdir//g;
        print ("![".$new_a."](.".$output."/".$new_a.")\n");
        print FILE ("![".$new_a."](.".$output."/".$new_a.")\n") 
      }
      print FILE ("\n---\n");
    close FILE;
  }
}
