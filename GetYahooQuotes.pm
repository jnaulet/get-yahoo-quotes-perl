#!/usr/bin/perl
package GetYahooQuotes;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(&get_yahoo_quotes);

use strict;
use warnings;

use String::Random;
use WWW::Curl::Easy;
use POSIX qw(strftime);

my $crumb = undef;
my $cookiejar = undef;

# Create cookiejar
sub get_cookiejar
{
    my $str = String::Random->new;
    return "/tmp/cookiejar_".strftime("%F@%T", localtime)."_".
	$str->randregex("[A-Za-z0-9]{32}");
}

# Get the crumb value
sub get_crumb
{
    my ($sym) = @_;
    
    my $curl = WWW::Curl::Easy->new;
    my $url = "https://finance.yahoo.com/quote/$sym/?p=$sym";
    
    $curl->setopt(CURLOPT_URL, $url);
    $curl->setopt(CURLOPT_COOKIEJAR, $cookiejar);
    $curl->setopt(CURLOPT_COOKIEFILE, $cookiejar);
    
    # Perform curl
    my $data;
    $curl->setopt(CURLOPT_WRITEDATA, \$data);
    $curl->perform;
    
    # Extract CrumbStore
    (my $crumb) = $data =~ m/{"crumb":"([a-zA-Z0-9\.]*)"}/g;
    return $crumb;
}

sub get_yahoo_quotes
{
    my ($sym, $filename) = @_;

    $cookiejar = get_cookiejar unless defined $cookiejar;
    $crumb = get_crumb($sym) unless defined $crumb;
    
    if(!defined $crumb){
	print STDERR "Unable to get crumb for $filename\n";
	return -1;
    }
    
    # Build URL
    my $url = "https://query1.finance.yahoo.com/v7/finance/download/$sym?".
	"period1=0&period2=".time()."&interval=1d&events=history&".
	"crumb=$crumb";

    my $curl = WWW::Curl::Easy->new;
    $curl->setopt(CURLOPT_URL, $url);
    $curl->setopt(CURLOPT_COOKIEFILE, $cookiejar);

    open my $file, '>', $filename or die "$filename: $!";
    $curl->setopt(CURLOPT_FILE, $file);
    
    # Starts the actual request
    return $curl->perform;
}
1;
