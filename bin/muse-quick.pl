#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Text::Amuse;

# quick and dirty to get the stuff compiled

foreach my $file (@ARGV) {
    unless ($file =~ m/\.muse$/ and -f $file) {
        warn "Skipping $file";
        next;
    }
    make_html($file);
    make_latex($file);
}

sub make_html {
    my $file = shift;
    my $doc = Text::Amuse->new(file => $file);
    my %headers = $doc->header_as_html;
    my $body = $doc->as_html;
    my $toc = $doc->toc_as_html;
    my $html = <<"EOF";
<!doctype html>
<html>
<head>
<meta charset="UTF-8">
<title>$file</title>
    <style type="text/css">
 <!--/*--><![CDATA[/*><!--*/

html,body, pre.verse {
	margin:0;
	padding:0;
	border: none;
 	background: transparent;
	font-family: Verdana, "DejaVu Sans", Helvetica, Arial, sans-serif;
	font-size: 10pt;
} 
div#page {
   margin:20px;
   padding:20px;
}
pre, code {
    font-family: Consolas, courier, monospace;
}
/* invisibles */
span.hiddenindex, span.commentmarker, .comment, span.tocprefix, #hitme {
    display: none
}

h1 { 
    font-size: 200%;
    margin: .67em 0
}
h2 { 
    font-size: 180%;
    margin: .75em 0
}
h3 { 
    font-size: 150%;
    margin: .83em 0
}
h4 { 
    font-size: 130%;
    margin: 1.12em 0
}
h5 { 
    font-size: 115%;
    margin: 1.5em 0
}
h6 { 
    font-size: 100%;
    margin: 0;
}

sup, sub {
    font-size: 8pt;
    line-height: 0;
}

/* invisibles */
span.hiddenindex, span.commentmarker, .comment, span.tocprefix, #hitme {
    display: none
}

.comment {
    background: rgb(255,255,158);
}

pre.verse {          
    margin: 24px 48px;
    overflow: auto;
    border: none;
} 

table, th, td {
    border: solid 1px black;
    border-collapse: collapse;
}
td, th {
    padding: 2px 5px;
}

hr {
    margin: 24px 0;
    color: #000;
    height: 1px;
    background-color: #000;
}

table {
    margin: 24px auto;
}

td, th { vertical-align: top; }
th {font-weight: bold;}

caption {
    caption-side:bottom;
}

img.embedimg {
    margin: 1em;
    max-width:90%;
}
div.image {
    margin: 1em;
    text-align: center;
    padding: 3px;
    background-color: white;
}

.biblio p, .play p {
  margin-left: 1em;
  text-indent: -1em;
}

div.biblio, div.play {
  padding: 24px 0;
}

div.caption {
    padding-bottom: 1em;
}

div.center {
    text-align: center;
}

div.right {
    text-align: right;
}

div#tableofcontents{
    padding:20px;
}

#tableofcontents p {
    margin: 3px 1em;
    text-indent: -1em;
}

.toclevel1 {
	font-weight: bold;
	font-size:11pt
}	

.toclevel2 {
	font-weight: bold;
	font-size: 10pt;
}

.toclevel3 {
	font-weight: normal;
	font-size: 9pt;
}

.toclevel4 {
	font-weight: normal;
	font-size: 8pt;
}


  /*]]>*/-->
    </style>
</head>
<body>
<div id="page">
<div class="header">
EOF

    foreach my $k (keys %headers) {
        $html .= "<div><strong>$k</strong>: $headers{$k}</div>";
    }
    $html .= qq{</div><div>$toc</div>\n<div class="thework">};
    $html .= $body;
    $html .= qq{</div></div></body></html>\n};
    my $out = $file;
    $out =~ s/muse$/html/;
    open (my $fh, ">:encoding(utf-8)", $out);
    print $fh $html;
    close $fh;
}

sub make_latex {
    my $file = shift;
    my $doc = Text::Amuse->new(file => $file);
    my $body = $doc->as_latex;
    my $latex = <<'EOF';
\documentclass[DIV=9,fontsize=10pt,oneside,paper=a5]{scrbook}
\usepackage{graphicx}
\usepackage{alltt}
\usepackage{verbatim}
\usepackage[hyperfootnotes=false,hidelinks,breaklinks=true]{hyperref}
\usepackage{bookmark}
\usepackage[stable]{footmisc}
\usepackage{enumerate}
\usepackage{longtable}
\usepackage[normalem]{ulem}

% avoid breakage on multiple <br><br> and avoid the next [] to be eaten
\newcommand*{\forcelinebreak}{~\\\relax}

\newcommand*{\hairline}{%
  \bigskip%
  \noindent \hrulefill%
  \bigskip%
}

% reverse indentation for biblio and play

\newenvironment{amusebiblio}{
  \leftskip=\parindent
  \parindent=-\parindent
  \bigskip
}{\bigskip}

\newenvironment{amuseplay}{
  \leftskip=\parindent
  \parindent=-\parindent
  \bigskip
}{\bigskip}

\newcommand{\Slash}{\slash\hspace{0pt}}
\title{Test}
\date{Test}
\author{Test}
\begin{document}

EOF
    my %headers = $doc->header_as_latex;
    foreach my $k (keys %headers) {
        $latex .= "\\textbf{$k}: $headers{$k}\n\n";
    }
    if ($doc->wants_toc) {
        $latex .= "\\tableofcontents\n"
    }
    $latex .= $body . "\n\\end{document}\n";
    my $out = $file;
    $out =~ s/muse$/tex/;
    open (my $fh, ">:encoding(utf-8)", $out);
    print $fh $latex;
    close $fh;
}
