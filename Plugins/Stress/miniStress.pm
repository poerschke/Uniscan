package Plugins::Stress::miniStress;

use Uniscan::Functions;
use Thread::Queue;
use threads;
use Uniscan::Http;
use Uniscan::Configure;
	
my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();


my $func = Uniscan::Functions->new();
my $q = new Thread::Queue;
my $max_threads  = 50;
my $time = 0;

sub new {
    my $class    = shift;
    my $self     = {name => "Mini Stress Test", version=>1.1};
	our $enabled  = 1;
	our $minuts = 1; 
    return bless $self, $class;
}


sub execute(){
	my ($self,@url) = @_;
	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| ". $conf{'lang114'} .":");
	$func->writeHTMLItem($conf{'lang114'} .":<br>");
	#aqui busca url mais custosa e retorna pra $url
	$url = &cost(@url);
	sleep(10);
	$func->write("| ". $conf{'lang115'} ." $url ". $conf{'lang116'});
	$func->writeHTMLValue($conf{'lang115'} . " $url " .$conf{'lang116'});
	$time = time() + ($minuts * 60);
	&threadnize("miniStress", $url);
	$func->write("| ".$conf{'lang117'}.".". " "x30);
	$func->writeHTMLValue($conf{'lang117'});
}


sub threadnize(){
	my ($fun, $test) = @_;
	for(my $i=0; $i<$max_threads+$max_threads;$i++){
		$q->enqueue($test);
	}


	my $x=0;
	my @threads = ();
	while($q->pending() && $x <= $max_threads){
		no strict 'refs';
		push @threads, threads->new(\&{$fun});
		sleep(20) if($q->pending() == 0);
		$x++;
	}

	sleep(2);
	foreach my $running (@threads) {
		$running->join();
	}
	@threads = ();
}



sub status(){
 my $self = shift;
 return $enabled;
}

sub miniStress(){


	while($q->pending > 0){
		print "| [*]  ". $conf{'lang121'} .": ". ($time  - time())."s           \r";
		if(($time  - time()) < 1 ){
			while($q->pending > 0){
				$q->dequeue;
			}
		return 1;
		}
	my $url = $q->dequeue;
	next if(not defined $url);
	$q->enqueue($url);
	&GET($url);
	}
	$q->enqueue(undef);
return 1;
}


sub cost(){
    my @urls = @_;
    my $target = "a";
    my $cost = 0;
    my $x = 0 ;
    my $y = scalar(@urls);
    my $http = Uniscan::Http->new();
    $func->write("| ". $conf{'lang118'} .":");
    $func->writeHTMLValue($conf{'lang118'} .":");
    foreach my $url (@urls){
	$x++;
	chomp $url;
	print "| ". $conf{'lang120'} ."[$x - $y]\r";
	my $time1 = time();
	my $ret = $http->GET($url);
	my $time2 = time();
	my $c = ($time2 - $time1);
	if($c > $cost){
	    $func->write("| ". $conf{'lang119'} .": [$c] $url");
	    $func->writeHTMLValue($conf{'lang119'} .": [$c] $url");
	    $cost = $c;
	    $target = $url;
	}
    }
    return $target;
    
    
}

sub GET(){
	my $url1 = shift;
	return if(!$url1);
	my $req = HTTP::Request->new(GET=>$url1);
	my $ua	= LWP::UserAgent->new(agent => $conf{'user_agent'});
	$ua->timeout(10);
	$ua->max_size(512);
	$ua->protocols_allowed( [ 'http'] );
	$ua->request($req);
}





1;
