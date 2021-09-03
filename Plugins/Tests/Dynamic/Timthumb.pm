package Plugins::Tests::Dynamic::Timthumb;

use Uniscan::Configure;
use Uniscan::Functions;
use Thread::Queue;
use Uniscan::Http;
use threads;

my $c = Uniscan::Configure->new(conffile => "uniscan.conf");
my $func = Uniscan::Functions->new();
my $http = Uniscan::Http->new();
my $q = new Thread::Queue;



sub new {
	my $class    = shift;
	my $self     = {name => "Timthumb <= 1.32 vulnerability", version=>1.0};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	return bless $self, $class;
}


sub execute(){
	my ($self,@urls) = @_;
	my %checks = ();
	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| ".$conf{'lang138'}.":");
	$func->writeHTMLItem($conf{'lang138'}.":<br>");
	my $protocol;
	my @check;
	my @files = (
		"timthumb.php"
	);


	foreach my $d (@urls){
		$protocol = 'http://' if($d =~/^http:\/\//);
		$protocol = 'https://' if($d =~/^https:\/\//);
		$d =~s/https?:\/\///g;
		substr($d, 0, rindex($d, '/'));
		while($d =~/\//){
			$d = substr($d, 0, rindex($d, '/'));
			foreach my $f (@files){
				my $u = $protocol . $d . '/' . $f;
				if(!$checks{$u}){
					$checks{$u} = 1;
					push(@check, $u);
				 }
			}
		}
	}
	&threadnize(@check);
}

sub clean{
	my $self = shift;
	%backdoors = ();
}



sub status(){
	my $self = shift;
	return $enabled;
}


sub findtimthumb(){
	my @matches = (
		"TimThumb version : (.+)<\/pre>",
	);

	while($q->pending() > 0){
		my $url1 = $q->dequeue;
		next if(not defined $url1);
		next if($url1 =~/#/g);
		print "[*] ".$conf{'lang65'}.": ". $q->pending  ."       \r";
		my $result = $http->GET($url1);
		foreach my $mat (@matches){
			if($result =~ m/$mat/gi){
				$func->write("| [+] Timthumb $1: $url1") if($1 < 1.33);
				$func->writeHTMLValue("Timthumb $1: $url1") if($1 < 1.33);
				$func->writeHTMLVul("TIMTHUMB") if($1 < 1.33);
			}
		}
	}
	$q->enqueue(undef);
}

sub threadnize(){
	my @tests = @_;
	foreach my $test (@tests){
		$q->enqueue($test) if($test);
	} 
	my $x=0;
	my @threads = ();
	while($q->pending() && $x <= $conf{'max_threads'}-1){
		push @threads, threads->new(\&findtimthumb);
		$x++;
	}

	sleep(2);
	foreach my $running (@threads) {
		$running->join();
		print "[*] ".$conf{'lang65'}.": ". $q->pending  ."       \r";
	}
	@threads = ();
}



1;
