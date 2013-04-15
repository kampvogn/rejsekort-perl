#!/usr/bin/perl 
use strict;
use warnings;

use TravelCard::Selfcare;

my $username = 'username'; ## Your username for https://selvbetjening.rejsekort.dk/CommercialWebSite  
my $password = 's3cret';   ## Your password

binmode( STDOUT, ':utf8');

my $selfcare = TravelCard::Selfcare->new('username' => $username, 'password' => $password);
$selfcare->history;
