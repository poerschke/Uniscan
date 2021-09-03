package Plugins::Tests::Dynamic::checkPHPCGI;

use Uniscan::Configure;
use Uniscan::Functions;
use Thread::Queue;
use Uniscan::Http;
use threads;

my $c = Uniscan::Configure->new(conffile => "uniscan.conf");
my $func = Uniscan::Functions->new();
my $q = new Thread::Queue;
my @vulns = ();

sub new {
	my $class    = shift;
	my $self     = {name => "PHP CGI Argument Injection", version=>1.1};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	
	return bless $self, $class;
}

sub execute(){
	my ($self,@urls) = @_;
	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| ". $conf{'lang130'} .":");
	$func->writeHTMLItem($conf{'lang130'} .":<br>");
	@urls = $func->remove(@urls) if(scalar(@urls));
	@urls = &generate(@urls);
	CheckVulns(@urls);
}

sub clean{
	my $self = shift;
	@vulns = ();
}

sub generate(){
	my @urls = @_;
	my @ret = ();
	foreach $url (@urls){
		chomp $url;
		substr($url, index($url, '?'), length($url)) = "" if($url =~ /\?/);
		push(@ret, $url) if($url =~/\.php$/i);
	}
	return @ret;
}

sub CheckVulns(){
	my @files = @_;
	my @xpl = ('?-s');
	my %bkp = ();
	my @file = ();
	my $url = "";
	foreach my $f (@files){
		chomp($f);
		next if($f =~/#/);
		foreach my $b (@xpl){
			if(!$bkp{$f.$b}){
				push(@file, $f.$b);
				$bkp{$f.$b} = 1;
			}			
		}
	}
	&threadnize("GetResponse", @file) if(scalar(@file));
}

sub status(){
	my $self = shift;
	return $enabled;
}

sub GetResponse(){
	my $http = Uniscan::Http->new();
	while($q->pending() > 0){
		my $url1 = $q->dequeue;
		next if(not defined $url1);
		next if($url1 =~/#/);
		print "[*] ".$conf{'lang65'}.": ". $q->pending  ."       \r";
		my $response = $http->GET($url1);
		if($response =~ /<code>.+\n<span style="color: #0000BB">/gi && $response =~ /&lt;\?/gi){
			$func->write("| [+] Vul: $url1");
			$func->writeHTMLValue("$url1");
			$func->writeHTMLVul("PHPCGI");
			push(@vulns, $url1);
		}
	}
	$q->enqueue(undef);
}

 sub threadnize(){
	my ($fun, @tests) = @_;
	foreach my $test (@tests){
		$q->enqueue($test) if($test);
	}
	my $x=0;
	my @threads = ();
	while($q->pending() && $x <= $conf{'max_threads'}-1){
		no strict 'refs';
		push @threads, threads->new(\&{$fun});
		$x++;
	}
	sleep(2);
	foreach my $running (@threads) {
		$running->join();
		print "[*] ". $conf{'lang65'}.": ". $q->pending  ."       \r";
	}
	@threads = ();
}
1;
