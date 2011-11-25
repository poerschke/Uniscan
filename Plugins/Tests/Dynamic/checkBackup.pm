package Plugins::Tests::Dynamic::checkBackup;

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
	my $self     = {name => "Find Backup Files", version=>1.1};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	our $q : shared = "";
	our @bkpf :shared = ();
	return bless $self, $class;
}


sub execute(){
	my ($self,@urls) = @_;

	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| Backup Files:");
	@urls = $func->remove(@urls) if(scalar(@urls));
	$func->INotPage($urls[1]);
	&threadnize("checkNoExist", @urls);
	CheckBackupFiles(@bkpf);
}

sub clean{
	my $self = shift;
	@bkpf = ();
}




sub CheckBackupFiles(){
	my @files = @_;
	
	my @backup = (	'.bak',
			'.bkp',
			'~',
			'.old',
			'.cpy',
			'.rar',
			'.zip',
			'.tar',
			'.tgz',
			'.ini',
			'.inc',
			'.gz',
			'.tmp',
			'.txt',
			'.bck',
			'.tar.gz'
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
	
	while($q->pending()){
		my $url1 = $q->dequeue;
		print "[*] Remaining tests: ". $q->pending ." Threads: " . (scalar(threads->list())+1) ."       \r";
		if($url1 =~/^https:\/\//){
			my $response = $http->GETS($url1);
			if($response){
				if($response =~ $conf{'code'} && $pattern !~ m/$response->content/){
					push(@list, $url1);
					if(length($url1) < 99){
						$func->write("| [+] CODE: " .$response."\t URL: $url1" . " "x(99 - length($url1)));
					}
					else {
						$func->write("| [+] CODE: " .$response."\t URL: $url1");
					}
				}
			}
			$response = 0;
			
		}

		else{
			my $req=HTTP::Request->new(GET=>$url1);
			my $ua=LWP::UserAgent->new(agent => "Uniscan ".$conf{'version'}." http://www.uniscan.com.br/");
			$ua->timeout($conf{'timeout'});
			$ua->max_size($conf{'max_size'});
			$ua->max_redirect(0);
			$ua->protocols_allowed( [ 'http'] );
			if($conf{'proxy'} ne "0.0.0.0" && $conf{'proxy_port'} != 65000){
				$ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
			}

			my $response=$ua->request($req);
			if($response){
				if($response->code =~ $conf{'code'} && $pattern !~ m/$response->content/){
					push(@list, $url1);
					if(length($url1) < 99){
						$func->write("| [+] CODE: " .$response->code."\t URL: $url1" . " "x(99 - length($url1)));
					}
					else {
						$func->write("| [+] CODE: " .$response->code."\t URL: $url1");
					}
				}
			}
			$req = 0;
			$ua = 0;
			$response = 0;
		}
	}
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


sub checkFile(){
	my $url1 = shift;

	if($url1 =~/^https:\/\//){
        	my $http = Uniscan::Http->new();
                my $response = $http->GETS($url1);
                if($response){
                	if($response =~ /200/){
				return 1;
			}
			else{ return 0;}
		}
	}

	if($url1 =~/^http:\/\//){
	 	use HTTP::Request;
		use LWP::UserAgent;
         
        	my $req=HTTP::Request->new(GET=>$url1);
        	my $ua=LWP::UserAgent->new(agent => "Uniscan ".$conf{'version'}." http://www.uniscan.com.br/");
        	$ua->timeout($conf{'timeout'});
        	$ua->max_size($conf{'max_size'});
                $ua->max_redirect(0);
                $ua->protocols_allowed( [ 'http'] );
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
	while($q->pending()){
		my $url1 = $q->dequeue;
		print "| [*] Creating tests ". $q->pending() ."    \r";
		if(&checkFile($url1."adad") != 1){
			push(@bkpf, $url1);
		}

	}
}


1;
