package Plugins::Tests::Static::checkLFI;

use Uniscan::Configure;
use Uniscan::Functions;
use Thread::Queue;
use Uniscan::Http;
use threads;

	my $c = Uniscan::Configure->new(conffile => "uniscan.conf");
	my $func = Uniscan::Functions->new();
	my $http = Uniscan::Http->new();

sub new {
    my $class    = shift;
    my $self     = {name => "Local File Include tests", version=>1.1};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	our $q : shared = "";
	our $vulnerable :shared = 0;
    return bless $self, $class;
}


sub execute(){
	my ($self,$url) = @_;

	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| LFI:");
    &ScanStaticLFI($url);
	}

	sub ScanStaticLFI(){
	my $url = shift;
	open(my $a, "<LFI") or die "$!\n";
	my @tests = <$a>;
	close($a);
	my @urls;
	foreach my $test (@tests){
		chomp $test;
		$test = urlencode($test) if($conf{'url_encode'} == 1);
		push(@urls, $url.$test);
	}
	&threadnize("TestLFI", @urls);
}

sub threadnize(){
	my ($fun, @tests) = @_;
	$q = 0;
	$q = new Thread::Queue;
	$tests[0] = 0;
	foreach my $test (@tests){
		$q->enqueue($test) if($test);
	}

	my $x=0;
	while($q->pending() && $x <= $conf{'max_threads'}-1){
		no strict 'refs';
		threads->new(\&{$fun});
		$x++;
	}

	my @threads = threads->list();
        foreach my $running (@threads) {
		$running->join();
		print "[*] Remaining tests: ". $q->pending ." Threads: " .(scalar(threads->list())+1) ."       \r";
        }
	@threads = ();
	$q = 0;
}


sub urlencode {
    my $s = shift;
    $s =~ s/ /+/g;
    $s =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
    $s =~s/%7C/\|/g;
    $s =~ s/%25/%/g;
    return $s;
}

sub status(){
 my $self = shift;
 return $enabled;
}

sub TestLFI(){

my ($resp, $test) = 0;
	while($q->pending){
		$test = $q->dequeue;
		print "[*] Remaining tests: ". $q->pending ." Threads: " .(scalar(threads->list())+1) ."       \r";
		$resp = $http->GET($test);
		if($resp =~/root:x:0:0:root/ || ($resp =~/boot loader/ && $resp =~/operating systems/ && $resp =~/WINDOWS/)){
			$vulnerable++;
			$func->write("| [+] Vul[$vulnerable] [LFI] $test");
		}
		$resp = 0;
	}
}

sub clean(){
 my $self = shift;
}

1;
