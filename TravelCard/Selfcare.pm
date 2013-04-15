package TravelCard::Selfcare;
use base 'Exporter';
our @EXPORT = qw(logout history);

use strict;

use WWW::Mechanize;
use HTML::TableExtract;
use HTML::Grabber;
use Data::Dumper qw(Dumper);

sub import {

  my($class, @fields) = @_;
  return unless @fields;
  my $caller = caller();

  # Build the code we're going to eval for the caller
  # Do the fields call for the calling package
  my $eval = "package $caller;\n" .
             "use fields qw( " . join(' ', @fields) . ");\n";

  # Generate convenient accessor methods
  foreach my $field (@fields) {
  	$eval .= "sub $field : lvalue { \$_[0]->{$field} }\n";
  }

  # Eval the code we prepared
  eval $eval;

  # $@ holds possible eval errors
  $@ and die "Error setting members for $caller: $@";
}

sub new {
  my $class = shift;

  my $self = {};
  my @validkeys = qw(username password);
  my %args = @_;

  foreach my $argname (keys %args) {
    if ($argname ~~ @validkeys) {     # smart matching
      $self->{$argname} = $args{$argname};
    }
  }

  bless($self, $class);

  return $self; 
}

sub DESTROY {
    my $self = shift;
  
    $self->logout();
}

sub _is_logged_in {
  my $self = shift;

  my $result = 0;

  if (exists($self->{'mech'})) {
    $self->{'mech'}->get('https://selvbetjening.rejsekort.dk/CommercialWebSite/CardServices/FrontPageCardOverview');
    my $dom = HTML::Grabber->new( html => $self->{'mech'}->content );
    $dom->find('span#loginname')->each(sub{
      my $login_name = $_->text;
      $login_name =~ s/^\s*//;
      $login_name =~ s/\s*$//;
      $result = 1 if ($login_name eq $self->{'username'});
    });
}

  return $result;
}

sub _trim {
  my $self = shift;

  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub history {
  my $self = shift;

  my $url = 'https://selvbetjening.rejsekort.dk/CommercialWebSite/TransactionServices/TravelCardHistory';

  if (! $self->_is_logged_in) {
    $self->login;
  }

  $self->{'mech'}->get($url);
  $self->{'mech'}->field('TravelSearch', -1);
  $self->{'mech'}->submit();

  my $te = HTML::TableExtract->new( headers => ['Dato', 'Fra', 'Til', "Bel\x{f8}b inkl. rabat"], attribs => {id => 'historyTravels'}, keep_headers => 1);
  $te->parse($self->{'mech'}->content);

  foreach my $ts ($te->tables) {
    foreach my $row ($ts->rows) {
      #print Dumper($row);
      for (my $i = 0; $i<@{$row};$i++) {
        if (defined($$row[$i])) {
          $$row[$i] =  $self->_trim($$row[$i]);
        }
      }
      print join(';', @$row);
      print "\n";
    }
  }
}

sub login {
  my $self = shift;

  my $login_url = 'https://selvbetjening.rejsekort.dk/CommercialWebSite/';
  
  $self->{'mech'} = WWW::Mechanize->new();
  $self->{'mech'}->get($login_url);

  $self->{'mech'}->field('registeredLogin', $self->{'username'});
  $self->{'mech'}->field('password', $self->{'password'});
  my $r = $self->{'mech'}->click;
  
  if (_is_logged_in) {
    $self->{'logged_in'} = 1;
    $self->_is_logged_in;
    print $self . "\n";
  }
  else {
    $self->{'logged_in'} = 0;
  }

}

sub logout {
  my $self = shift;
  
  my $logout_url = 'https://selvbetjening.rejsekort.dk//CommercialWebSite/CustomerManagement/Logout';

  if ($self->_is_logged_in) {
    my $r = $self->{'mech'}->get($logout_url);
  }
}

1;
