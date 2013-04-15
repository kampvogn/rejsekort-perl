#!/usr/bin/perl 
use strict;
use warnings;

use Getopt::Std;
use TravelCard::Selfcare;

my $username = ''; ## Your username for https://selvbetjening.rejsekort.dk/CommercialWebSite  
my $password = ''; ## Your password

my %opts;
getopt('u:p:', \%opts);

if (exists($opts{'u'}) && $username eq '') {
  $username = $opts{'u'};
}

if (exists($opts{'p'}) && $password eq '') {
  $password = $opts{'p'};
}

binmode( STDOUT, ':utf8');

my $selfcare = TravelCard::Selfcare->new('username' => $username, 'password' => $password);
$selfcare->history;
