package Plugins::Tests::Dynamic::checkSQLI;

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
	my $self     = {name => "SQL-injection tests", version=>1.1};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	our $q : shared = "";
	our $vulnerable :shared = 0;
	return bless $self, $class;
}


sub execute(){
	my ($self,@urls) = @_;
	our @SQL = (
		"'",
		";",
		"\""
	);
	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| SQL-i:");
	&ScanSQLCrawler(@urls);	
	&ScanSQLCrawlerPost(@urls);
}

sub clean{
	my $self = shift;
	$vulnerable = 0;
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
	while($q->pending){
		my $test = $q->dequeue;
		print "[*] Remaining tests: ". $q->pending ." Threads: " .(scalar(threads->list())+1) ."       \r";
		my $resp = $http->GET($test);
		if($resp =~/You have an error in your SQL syntax|Microsoft OLE DB Provider for ODBC Drivers|Supplied argument is not a valid .* result|Unclosed quotation mark after the character string/){
			$vulnerable++;
			$func->write("| [+] Vul[$vulnerable] [SQL-i] $test               ");
		}
		$resp = 0;
	}
}


sub TestSQLPost(){
	while($q->pending){
		my $test = $q->dequeue;
		my ($url, $data) = split('#', $test);
		print "[*] Remaining tests: ". $q->pending ." Threads: " .(scalar(threads->list())+1) ."       \r";
		my $resp = $http->POST($url, $data);
		if($resp =~/You have an error in your SQL syntax|Microsoft OLE DB Provider for ODBC Drivers|Supplied argument is not a valid .* result|Unclosed quotation mark after the character string/){
			$vulnerable++;
			$func->write("| [+] Vul[$vulnerable] [SQL] $url               \n| Post data: $data               ");
		}
		$resp = 0;
	}
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
						$temp =~ s/\Q$variables[$x]\E/$t/g;
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


sub urlencode {
    my $s = shift;
    $s =~ s/ /+/g;
    $s =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
    $s =~s/%7C/\|/g;
    $s =~ s/%25/%/g;
    return $s;
}

















1;
