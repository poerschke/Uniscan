package Plugins::Tests::Dynamic::checkRFI;

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
	my $self     = {name => "Remote File Include tests", version => 1.2};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	return bless $self, $class;
}


sub execute(){
	my ($self, @urls) = @_;
	our @RFI = ('http://uniscan.sourceforge.net/c.txt?');
	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| ".$conf{'lang143'}.":");
	$func->writeHTMLItem($conf{'lang143'}.":<br>");
    &ScanRFICrawler(@urls);	
    &ScanRFICrawlerPost(@urls);
}


sub clean{
	my $self = shift;

}


sub ScanRFICrawler(){
	my @urls = @_;
	my @tests = &GenerateTests("RFI", @urls);
	@tests = $func->remove(@tests) if(scalar(@tests));
	&threadnize("TestRFI", @tests) if(scalar(@tests));
}

sub ScanRFICrawlerPost(){
	my @urls = @_;
	my @tests = &GenerateTestsPost("RFI", @urls);
	@tests = $func->remove(@tests) if(scalar(@tests));
	&threadnize("TestRFIPost", @tests) if(scalar(@tests));
}

sub TestRFI(){
my ($resp, $test) = 0;
	while($q->pending > 0){
		$test = $q->dequeue;
		next if(not defined $test);
		next if($test =~/#/g);
		print "[*] Remaining tests: ". $q->pending  ."       \r";
		$resp = $http->GET($test);
		if($resp =~/$conf{'rfi_return'}/){
			$func->write("| [+] Vul [RFI] $test  ");
			$func->writeHTMLValue($test);
			$func->writeHTMLVul("RFI");
		}
		$resp = 0;
	}
	$q->enqueue(undef);
}


##############################################
#  Function TestRFIPost
#  this function test RFI Vulnerabilities 
#  on forms
#
#  Param: $test
#  Return: nothing
##############################################

sub TestRFIPost(){

my ($resp, $test) = 0;
	while($q->pending > 0){
		$test = $q->dequeue;
		next if(not defined $test);
		next if($test !~/#/g);
		my ($url, $data) = split('#', $test);
		print "[*] Remaining tests: ". $q->pending  ."       \r";
		$resp = $http->POST($url, $data);
		if($resp =~/$conf{'rfi_return'}/){
			$func->write("| [+] Vul [RFI] $url               \n| ".$conf{'lang129'}.": $data               ");
			$func->writeHTMLValue($url."<br>".$conf{'lang129'}.": $data");
			$func->writeHTMLVul("BSQL-I");
		}
		$resp = 0;
	}
	$q->enqueue(undef);
}



##############################################
#  Function GenerateTests
#  this function generate the tests
#
#
#  Param: $test, @list
#  Return: @list_of_tests
##############################################

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
  

##############################################
#  Function threadnize
#  this function threadnize any function in this
#  module
#
#  Param: $function, @tests
#  Return: nothing
##############################################


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
		print "[*] Remaining tests: ". $q->pending  ."       \r";
	}
	@threads = ();
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

1;
