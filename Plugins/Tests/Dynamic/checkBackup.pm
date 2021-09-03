package Plugins::Tests::Dynamic::checkBackup;

use Uniscan::Configure;
use Uniscan::Functions;
use Thread::Queue;
use Uniscan::Http;
use Thread::Semaphore;
use threads;
use LWP::Protocol::https;


	my $c = Uniscan::Configure->new(conffile => "uniscan.conf");
	my $func = Uniscan::Functions->new();
	my $http = Uniscan::Http->new();
	my $q = new Thread::Queue;
	my @bkpf :shared = ();
	my $semaphore = Thread::Semaphore->new();
	
sub new {
	my $class    = shift;
	my $self     = {name => "Find Backup Files", version=>1.2};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();

	return bless $self, $class;
}


sub execute(){
	my ($self,@urls) = @_;

	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| ". $conf{'lang124'} .":");
	$func->writeHTMLItem($conf{'lang124'} .":<br>");
	my $u = "";
	foreach (@urls){
		if(/^https?:\/\//){
			$u = $_;
			last;
		}
	}
	substr($u, index($u, '?'), length($u)) = "" if($u =~/\?/g);
	$u = substr($u, 0, rindex($u, '/'));
	my $req = $u . '/testing123';
	my $r = $http->HEAD($req);
	if($r->code !~/404/ && $conf{'force_bf'} == 0){
		$func->write("| ".$conf{'lang12'}." $req ". $conf{'lang13'});
		$func->writeHTMLValue($conf{'lang12'}." $req ". $conf{'lang13'});
	}
	else{
		@urls = $func->remove(@urls) if(scalar(@urls));
		$func->INotPage($urls[1]);
		&threadnize("checkNoExist", @urls);
		CheckBackupFiles(@bkpf);
	}
	
}

sub clean{
	my $self = shift;
	@bkpf = ();
}




sub CheckBackupFiles(){
	my @files = @_;
	
	my @backup = (	'.bkp',
			'~',
		    );
	my %bkp = ();
	my @file = ();
	my $url = "";
	foreach my $f (@files){
		chomp($f);
		next if($f =~/#/);
		$url = $func->get_url($f);
		my $fi = $func->get_file($f);
		next if($fi =~/\.css$/);
		substr($fi, length($fi)-1, length($fi)) = "" if(substr($fi, length($fi)-1, length($fi)) eq "/");
		foreach my $b (@backup){
			my $fil = $fi . $b;
			if(!$bkp{$fil}){
				push(@file, $url.$fil) if($fil =~/\//);
				$bkp{$fil} = 1;
			}
			
		}
	}
	checkBackup(@file);
}


sub status(){
	my $self = shift;
	return $enabled;
}


sub checkBackup(){
	my @bkp = @_;
	&threadnize("GetResponse", @bkp) if(scalar(@bkp));
}


sub GetResponse(){
	
	while($q->pending() > 0){
		my $url1 = $q->dequeue;
		next if(not defined $url1);
		next if($url1 !~/^https?:\/\//);
		next if($url1 =~/#/);
		print "[*] ". $conf{'lang65'} .": ". $q->pending ."       \r";


			my $req=HTTP::Request->new(GET=>$url1);
			my $ua=LWP::UserAgent->new(agent => $conf{'user_agent'} );
			$ua->timeout($conf{'timeout'});
			$ua->max_size($conf{'max_size'});
			$ua->max_redirect(0);
			$ua->protocols_allowed( [ 'http', 'https'] );
			if($conf{'use_proxy'} == 1){
				$ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
			}

			my $response=$ua->request($req);
			if($response){
				if($response->code =~ $conf{'code'} && $pattern !~ m/$response->content/){
					print " "x35 . "\r";
					$func->write("| [+] ".$conf{'lang84'}.": " .$response->code." URL: $url1");
					$func->writeHTMLValue($conf{'lang84'}.": " .$response->code." URL: $url1");
				}
			}
	}
	$q->enqueue(undef);
}


 sub threadnize(){
	my ($fun, @tests) = @_;
	$tests[0] = 0;
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
		print "[*] ". $conf{'lang65'} .": ". $q->pending ."       \r";
	}
	@threads = ();
}


sub checkFile(){
	my $url1 = shift;

	if($url1 =~/^https?:\/\//){
	 	use HTTP::Request;
		use LWP::UserAgent;
         
        	my $req=HTTP::Request->new(GET=>$url1);
        	my $ua=LWP::UserAgent->new(agent => $conf{'user_agent'});
        	$ua->timeout($conf{'timeout'});
        	$ua->max_size($conf{'max_size'});
                $ua->max_redirect(0);
                $ua->protocols_allowed( [ 'http', 'https'] );
                if($conf{'proxy'} ne "0.0.0.0" && $conf{'proxy_port'} != 65000){
                	$ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
               	}

                my $response=$ua->request($req);
                if($response){
                	if($response->code =~ /200/){
				return 1;
			}
			else{ return 0; }
		}
		else{
			return 1;
		}
	}
return 0;
}

sub checkNoExist(){
	while($q->pending() > 0){
		my $url1 = $q->dequeue;
		next if(not defined $url1);
		print "| [*] ". $conf{'lang125'} ." ". $q->pending() ."    \r";
		if(&checkFile($url1."adad") != 1){
			$semaphore->down();
			push(@bkpf, $url1);
			$semaphore->up();
		}
	}
	$q->enqueue(undef);
}


1;
