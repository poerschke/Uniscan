package Plugins::Tests::Dynamic::checkSQLI;

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
	my $self     = {name => "SQL-injection tests", version=>1.2};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	return bless $self, $class;
}


sub execute(){
	my ($self,@urls) = @_;
	our @SQL = (
		"'",
		"\""
	);
	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| ". $conf{'lang132'} .":");
	$func->writeHTMLItem($conf{'lang132'} .":<br>");
	&ScanSQLCrawler(@urls);	
	&ScanSQLCrawlerPost(@urls);
}

sub clean{
	my $self = shift;

}


sub ScanSQLCrawler(){
	my @urls = @_;
	my @tests = &GenerateTestsSql("SQL", @urls) if(scalar(@urls));
	@tests = $func->remove(@tests) if(scalar(@tests));
	&threadnize("TestSQL", @tests) if(scalar(@tests));
}

sub ScanSQLCrawlerPost(){
	my  @urls = @_;
	my @tests = &GenerateTestsPostSql("SQL", @urls);
	@tests = $func->remove(@tests) if(scalar(@tests));
	&threadnize("TestSQLPost", @tests) if(scalar(@tests));
}

sub TestSQL(){
	while($q->pending > 0){
		my $test = $q->dequeue;
		next if(not defined $test);
		if($test !~/#/){
			print "[*] ".$conf{'lang65'}.": ". $q->pending  ."       \r";
			my $resp = $http->GET($test);
			if($resp =~/You have an error in your SQL syntax|Microsoft OLE DB Provider for ODBC Drivers|Supplied argument is not a valid .* result|Unclosed quotation mark after the character string/i){
				$func->write("| [+] Vul [SQL-i] $test               ");
				$func->writeHTMLValue($test);
				$func->writeHTMLVul("SQL-I");
			}
			$resp = 0;
		}
	}
	$q->enqueue(undef);
}


sub TestSQLPost(){
	while($q->pending > 0){
		my $test = $q->dequeue;
		next if(not defined $test);
		if($test =~/#/){
			my ($url, $data) = split('#', $test);
			print "[*] ".$conf{'lang65'}.": ". $q->pending  ."       \r";
			my $resp = $http->POST($url, $data);
			if($resp =~/You have an error in your SQL syntax|Microsoft OLE DB Provider for ODBC Drivers|Supplied argument is not a valid .* result|Unclosed quotation mark after the character string/i){
				$func->write("| [+] Vul [SQL-i] $url               \n| ".$conf{'lang129'}.": $data               ");
				$func->writeHTMLValue($url."<br>".$conf{'lang129'}.": $data");
				$func->writeHTMLVul("SQL-I");
			}
			$resp = 0;
		}
	}
	$q->enqueue(undef);
}



sub GenerateTestsSql(){
	my ($test, @list) = @_;
	my @list2 = ();
	foreach my $line (@list){
		$line =~ s/&amp;/&/g;
		$line =~ s/\[\]//g;
		if($line =~ /=/){
			my $temp = $line;
			$temp = substr($temp,index($temp, '?')+1,length($temp));
			my @variables = split('&', $temp);
			for(my $x=0; $x< scalar(@variables); $x++){
				no strict 'refs';
				if($variables[$x]){
					foreach my $str (@{$test}){
						$temp = $line;
						$str = urlencode($str) if($conf{'url_encode'} == 1);
						my $t = $variables[$x] . $str;
						$temp =~ s/\Q$variables[$x]\E//g;
						$t = "&" . $t if($t !~/^&/);
						$temp .= $t;
						$temp =~ s/&&/&/g;
						$temp =~ s/\?&/\?/g;
						push(@list2, $temp);
					}
				}
			}
		}
	}
	@list = ();
	return @list2;
}


sub GenerateTestsPostSql(){
	my ($test, @list) = @_;
	my @list2 = ();
	foreach my $line (@list){
		my ($url, $line) = split('#', $line);
		$line =~ s/&amp;/&/g;
		$line =~ s/\[\]//g;
		if($line =~ /=/){
			my $temp = $line;
			$temp = substr($temp,index($temp, '?')+1,length($temp));
			my @variables = split('&', $temp);
			for(my $x=0; $x< scalar(@variables); $x++){
				no strict 'refs';
				if($variables[$x]){
					foreach my $str (@{$test}){
						$temp = $line;
						$str = urlencode($str) if($conf{'url_encode'} == 1);
						my $t = $variables[$x] . $str;
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
	while($q->pending() && $x <= $conf{'max_threads'}-1){
		no strict 'refs';
		push @threads, threads->new(\&{$fun});
		$x++;
	}

	sleep(2);
	foreach my $running (@threads) {
		$running->join();
		print "[*] ". $conf{'lang65'}.": ". $q->pending  ."       \r";
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



1;
