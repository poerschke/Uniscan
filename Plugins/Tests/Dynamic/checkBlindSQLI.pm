package Plugins::Tests::Dynamic::checkBlindSQLI;

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
	my $self     = {name => "Blind SQL-injection tests", version => 1.0};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	our $q : shared = "";
	our $vulnerable :shared = 0;
	return bless $self, $class;
}


sub execute(){
	my ($self,@urls) = @_;

	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| Blind SQL-i:");
	@urls = $func->remove(@urls) if(scalar(@urls));
	&threadnize("CheckNoError", @urls) if(scalar(@urls));
}

sub clean{
	my $self = shift;
	$vulnerable = 0;
}


sub CheckNoError(){
	while($q->pending){
		my $url = $q->dequeue;
		if($url !~/#/){
			print "[*] Remaining tests: ". $q->pending ." Threads: " .(scalar(threads->list())+1) ."       \r";
			if($url =~/\?/){
				my ($url1, $vars) = split('\?', $url);
				my @var = split('&', $vars);
				foreach my $v (@var){
					TestNoError($url, $v);
				}
			}
		}
	}
}


sub TestNoError(){
	my ($url, $var) = @_;
	my $url1 = $url;
	$url1 =~ s/$var/$var\+AND\+1=1/g;
	my $url2 = $url;
	$url2 =~ s/$var/$var\+AND\+1=2/g;
	my $r1 = $http->GET($url);
	my $r2 = $http->GET($url);
	my $r4 = $http->GET($url2);
	my $r5 = $http->GET($url1);
	my @w1 = split(' ', $r1);
	my $keyword = "";
	my $key = 0;
	foreach my $word (@w1){
		if($r2 =~ m/\Q$word\E/ && $r4 !~m/\Q$word\E/ && length($word) > 5 && $word =~ m/^\w+$/g){
			if($key == 0){
				$key =1;
				$keyword = $word;
			}
		}
	}

	if($r5 =~/$keyword/ && $key == 1 && $r5 !~/<b>Warning<\/b>.+\[<a href='function/ && $r4 !~/\Q$keyword\E/){
		$vulnerable++;
		$func->write("| [+] Vul[$vulnerable] [Blind SQL-i]: $url1               ");
	}
	($r1, $r2, $r4, $r5, @w1, $keyword) = 0
}


sub status(){
 my $self = shift;
 return $enabled;
}

 sub threadnize(){
	my ($fun, @tests) = @_;
	$q = 0;
	$q = new Thread::Queue;
	$tests[0] = 0;
	foreach my $test (@tests){
		$q->enqueue($test) if($test && $test =~/=/);
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



1;
