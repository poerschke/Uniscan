package Plugins::Stress::miniStress;

use Uniscan::Functions;
use Thread::Queue;
use threads;

my $func = Uniscan::Functions->new();

sub new {
    my $class    = shift;
    my $self     = {name => "Mini Stress Test", version=>1.0};
	our $enabled  = 1;
	our $q : shared = "";
	our $max_threads :shared = 50;
	our $minuts = 1; 
	our $time : shared = 0;
    return bless $self, $class;
}


sub execute(){
	my ($self,$url) = @_;
	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| Mini Stress Test:");
	$time = time() + ($minuts * 60);

	&threadnize("miniStress", $url);
	$func->write("| Mini Stress Test End.");
	}


sub threadnize(){
	my ($fun, $test) = @_;
	$q = new Thread::Queue;
	for(my $i=0; $i<$max_threads+$max_threads;$i++){
		$q->enqueue($test);
	}


	my $x=0;
	while($q->pending() && $x <= $max_threads){
		no strict 'refs';
		threads->new(\&{$fun});
		sleep(20) if($q->pending() == 0);
		$x++;
	}

	my @threads = threads->list();
        foreach my $running (@threads) {
		$running->join();
        }
	@threads = ();
	$q = 0;
}



sub status(){
 my $self = shift;
 return $enabled;
}

sub miniStress(){


	while($q->pending){
		print "| [*] Threads: ". scalar(threads->list()) ." Remaining time: ". ($time  - time())."s           \r";
		if(($time  - time()) < 1 ){
			while($q->pending){
				$q->dequeue;
			}
		return 1;
		}
	my $url = $q->dequeue;
	$q->enqueue($url);
	&GET($url);
	}
return 1;
}




sub GET(){
	my $url1 = shift;
	return if(!$url1);
	my $req = HTTP::Request->new(GET=>$url1);
	my $ua	= LWP::UserAgent->new(agent => "Uniscan Stress test http://www.uniscan.com.br/");
	$ua->timeout(10);
	$ua->max_size(512);
	$ua->protocols_allowed( [ 'http'] );
	$ua->request($req);
}





1;
