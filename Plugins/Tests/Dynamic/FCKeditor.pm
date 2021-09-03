package Plugins::Tests::Dynamic::FCKeditor;

use Uniscan::Configure;
use Uniscan::Functions;
use Thread::Queue;
use Uniscan::Http;
use threads;
use threads::shared;
use Thread::Semaphore;
use URI;

my $c = Uniscan::Configure->new(conffile => "uniscan.conf");
my $func = Uniscan::Functions->new();
my $http = Uniscan::Http->new();
my @dirs = (	"/FCKeditor/editor/",
		"/fckeditor/editor/");
our @fck : shared = ();
my $q = Thread::Queue->new();
my %check = ();
my $semaphore = Thread::Semaphore->new();

sub new {
	my $class    = shift;
	my $self     = {name => "FCKedior tests", version=>1.1};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();	
	return bless $self, $class;
}


sub execute(){
	my ($self,@urls) = @_;
	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| ".$conf{'lang137'}.":");
	$func->writeHTMLItem($conf{'lang137'} .":<br>");
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
	my $res = $http->HEAD($u . '/testing123');
	if($res->code !~ /404/ && $conf{'force_bf'} == 0){
		$func->write("| ".$conf{'lang12'}." $req ". $conf{'lang13'});
		$func->writeHTMLValue($conf{'lang12'}." $req ". $conf{'lang13'});
	}
	else {
		foreach my $url (@urls){
			my $u = &host($url);
			my $temp = $url;
			my $ub = 2000;
			while($ub > 11){
				$ub = rindex($temp, '/');
				$temp = substr($temp, 0, $ub);
				foreach my $dir (@dirs){
					if($temp =~ /$u/){
						$temp =~s/\r|\n//g;
						$check{$temp.$dir} =  1 if(!$check{$temp.$dir});
					}
				}
				$ub = rindex($temp, '/');
			}
		}
		my @urls = ();
		foreach my $url	(keys %check){
			push(@urls, $url);
		}
		&threadnize("checkNoExist", @urls);
		&CheckUpload(@fck) if(scalar(@fck));
	}
}

sub clean{
	my $self = shift;
	@fck = ();
	%check = ();
}




sub CheckUpload(){
	my @files = @_;
	my @forms = ();
	my @connectors = (	"filemanager/upload/cfm/upload.cfm",
				"filemanager/upload/php/upload.php",
				"filemanager/upload/asp/upload.asp",
				"filemanager/upload/aspx/upload.aspx",
				"filemanager/upload/perl/upload.cgi",
				"filemanager/upload/py/upload.py");
	foreach my $f (@files){
		foreach my $con (@connectors){
			push(@forms, $f. $con);
		}
	}
	@files = ();
	&threadnize("Upload", @forms) if(scalar(@forms));
	
}


sub status(){
	my $self = shift;
	return $enabled;
}





 sub threadnize(){
	my ($fun, @tests) = @_;
	foreach my $test (@tests){
		$q->enqueue($test) if($test);
	}
	my $x=0;
	my @threads = ();
	while($q->pending() > 0 && $x <= $conf{'max_threads'}-1){
		no strict 'refs';
		push @threads, threads->new(\&{$fun});
		$x++;
	}

	sleep(2);
	foreach my $running (@threads) {
		$running->join();
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
                if($conf{'use_proxy'} == 1){
                	$ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
               	}
                my $response=$ua->request($req);
                if($response){
                	if($response->code =~ /200|302/){
				return 1;
			}
			else{ return 0; }
		}
		else{
			return 0;
		}
	}
return 0;
}

sub checkNoExist(){
	while($q->pending() > 0){
		my $url1 = $q->dequeue;
		next if(not defined $url1);
		next if($url1 =~/#/g);
		print "| [*] ".$conf{'lang134'}." ". $q->pending() ."    \r";
		if(&checkFile($url1) == 1){
			$semaphore->down();
			push(@fck, $url1);
			$semaphore->up();
		}
	}
	$q->enqueue(undef);
}


sub Upload(){
	while($q->pending() > 0){
		my $url = $q->dequeue;
		next if(not defined $url);
		next if(!$url);
		next if($url =~/#/g);
		next if($url !~/^https?:\/\//);
		print "| [*] ".$conf{'lang135'}." ". $q->pending() ."    \r";
		my $host = &host($url);
		my $temp = $url;
		$temp =~ s/https?:\/\///g;
		$temp =~ s/$host//g;
		my $path = $temp;
		my $sock = IO::Socket::INET->new (PeerAddr => $host,PeerPort => 80, Proto    => 'tcp') || next;
		print $sock "POST ". $path ." HTTP/1.1\r\n" ;
		print $sock "Host: ".$host."\r\n" ;
		print $sock "User-Agent:Mozilla/5.0 (X11; U; Linux i686; pt-BR; rv:1.9.2.24) Gecko/20111107 Ubuntu/10.10 (maverick) Firefox/3.6.24\r\n" ;
		print $sock 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'."\r\n" ;
		print $sock 'Accept-Language: pt-br,pt;q=0.8,en-us;q=0.5,en;q=0.3'."\r\n" ;
		print $sock 'Accept-Encoding: gzip,deflate'."\r\n" ;
		print $sock 'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7'."\r\n" ;
		print $sock 'Keep-Alive: 115'."\r\n" ;
		print $sock 'Connection: keep-alive'."\r\n" ;
		print $sock 'Referer: http://'. $host .'/FCKeditor/editor/filemanager/upload/test.html'."\r\n" ;
		print $sock 'Content-Type: multipart/form-data; boundary=---------------------------3404088951808214906347034904'."\r\n" ;
		print $sock 'Content-Length: 236'."\r\n\r\n" ;
		print $sock '-----------------------------3404088951808214906347034904'."\r\n" ;
		print $sock 'Content-Disposition: form-data; name="NewFile"; filename="uniscan.txt"'."\r\n" ;
		print $sock 'Content-Type: text/plain'."\r\n" ;
		print $sock "\r\n" ;
		print $sock 'teste uniscan'."\n" ;
		print $sock "\r\n" ;
		print $sock '-----------------------------3404088951808214906347034904--'."\r\n" ;
		my $result;
		while(<$sock>){
			$result .= $_;
		}
		$result =~/OnUploadCompleted\((\d+)\,"(.*)"\,"(.*)"\, ""\)/;
		my $code = $1;
		my $path_file = $2;
		my $file_name = $3;
		if($code == 201 && $path_file =~/uniscan/ && $file_name=~/uniscan/){
			$func->write("| [+] http://" . $host . $path . " ".$conf{'lang136'}." http://" . $host. $path_file);
			$func->writeHTMLValue("http://" . $host . $path . " ".$conf{'lang136'}." http://" . $host. $path_file);
			$func->writeHTMLVul("FCKEDITOR");
		}
	}
	$q->enqueue(undef);
}

sub host(){
  	my $h = shift;
  	my $url1 = URI->new( $h || return -1 );
  	return $url1->host();
}

1;



