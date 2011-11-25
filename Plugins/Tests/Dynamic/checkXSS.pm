package Plugins::Tests::Dynamic::checkXSS;

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
	my $self     = {name => "Cross-Site Scripting tests", version=>1.0};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	our $q : shared = "";
	our $vulnerable :shared = 0;
	return bless $self, $class;
}


sub execute(){
	my ($self,@urls) = @_;
	our @XSS = (
		"\"><script>alert('XSS')</script>",
		"<script>alert('XSS')</script>",
		"'';!--\"<XSS>=&{()}",
		"\">'';!--\"<XSS>=&{()}",
		"<IMG SRC=\"javascript:alert('XSS');\">",
		"\"><IMG SRC=\"javascript:alert('XSS');\">",
		"<IMG SRC=javascript:alert(&quot;XSS&quot;)>",
		"\"><IMG SRC=javascript:alert(&quot;XSS&quot;)>",
		"<IMG SRC=\"javascript:alert('XSS')\"",
		"\"><IMG SRC=\"javascript:alert('XSS')\"",
		"<LINK REL=\"stylesheet\" HREF=\"javascript:alert('XSS');\">",
		"\"><LINK REL=\"stylesheet\" HREF=\"javascript:alert('XSS');\">",
		"<META HTTP-EQUIV=\"refresh\" CONTENT=\"0; URL=http://;URL=javascript:alert('XSS');\">",
		"\"><META HTTP-EQUIV=\"refresh\" CONTENT=\"0; URL=http://;URL=javascript:alert('XSS');\">",
		"<DIV STYLE=\"background-image: url(javascript:alert('XSS'))\">",
		"\"><DIV STYLE=\"background-image: url(javascript:alert('XSS'))\">",
		"<body onload=\"javascript:alert('XSS')\"></body>",
		"\"><body onload=\"javascript:alert('XSS')\"></body>",
		"<table background=\"javascript:alert('XSS')\"></table>",
		"\"><table background=\"javascript:alert('XSS')\"></table>",
	);

	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| XSS:");
	&ScanXSSCrawler(@urls);	
	&ScanXSSCrawlerPost(@urls);
}

sub clean{
	my $self = shift;
	$vulnerable = 0;
}



sub ScanXSSCrawler(){
	my @urls = @_;
	my @tests = &GenerateTests("XSS", @urls);
	@tests = $func->remove(@tests) if(scalar(@tests));
	&threadnize("TestXSS", @tests) if(scalar(@tests));
}

sub ScanXSSCrawlerPost(){
	my @urls = @_;
	my @tests = &GenerateTestsPost("XSS", @urls);
	@tests = $func->remove(@tests) if(scalar(@tests));
	&threadnize("TestXSSPost", @tests) if(scalar(@tests));
}


sub TestXSS(){
	while($q->pending){
		my $test = $q->dequeue;
		print "[*] Remaining tests: ". $q->pending ." Threads: " .(scalar(threads->list())+1) ."       \r";
		my $resp = $http->GET($test);
		if($resp =~ m/<[\w|\s|\t|\n|\r|'|"|\?|\[|\]|\(|\)|\*|&|%|\$|#|@|!|\|\/|,|\.|;|:|\^|~|\}|\{|\+|\-|=|_]+>[_|=|\w|\s|\t|\n|\r|'|"|\?|\[|\]|\(|\)|\*|&|%|\$|#|@|!|\|\/|,|\.|;|:|\^|~|\}|\{|\+|\-]*(<script>alert\('XSS'\)<\/script>|<XSS>|<IMG SRC=\"javascript:alert\('XSS'\);\">|<IMG SRC=javascript:alert\(&quot;XSS&quot;\)>|<IMG SRC=javascript:alert\(String.fromCharCode\(88,83,83\)\)>|<IMG SRC=javascript:alert('XSS')>|<IMG SRC=\"javascript:alert\('XSS'\)\">|<LINK REL=\"stylesheet\" HREF=\"javascript:alert\('XSS'\);\">|<IMG SRC='vbscript:msgbox\(\"XSS\"\)'>|<META HTTP-EQUIV=\"refresh\" CONTENT=\"0; URL=http:\/\/;URL=javascript:alert\('XSS'\);\">|<DIV STYLE=\"background-image: url\(javascript:alert\('XSS'\)\)\">|<body onload=\"javascript:alert\('XSS'\)\"><\/body>|<table background=\"javascript:alert\('XSS'\)\"><\/table>).*</i){
			$vulnerable++;
			$func->write("| [+] Vul[$vulnerable] [XSS] $test               ");
		}
		$resp = 0;
	}
}



sub TestXSSPost(){
	while($q->pending){
		my $test = $q->dequeue;
		my ($url, $data) = split('#', $test);
		print "[*] Remaining tests: ". $q->pending ." Threads: " .(scalar(threads->list())+1) ."       \r";
		my $resp = $http->POST($url, $data);
		if($resp =~ m/<[\w|\s|\t|\n|\r|'|"|\?|\[|\]|\(|\)|\*|&|%|\$|#|@|!|\|\/|,|\.|;|:|\^|~|\}|\{|\+|\-|=|_]+>[_|=|\w|\s|\t|\n|\r|'|"|\?|\[|\]|\(|\)|\*|&|%|\$|#|@|!|\|\/|,|\.|;|:|\^|~|\}|\{|\+|\-]*(<script>alert\('XSS'\)<\/script>|<XSS>|<IMG SRC=\"javascript:alert\('XSS'\);\">|<IMG SRC=javascript:alert\(&quot;XSS&quot;\)>|<IMG SRC=javascript:alert\(String.fromCharCode\(88,83,83\)\)>|<IMG SRC=javascript:alert('XSS')>|<IMG SRC=\"javascript:alert\('XSS'\)\">|<LINK REL=\"stylesheet\" HREF=\"javascript:alert\('XSS'\);\">|<IMG SRC='vbscript:msgbox\(\"XSS\"\)'>|<META HTTP-EQUIV=\"refresh\" CONTENT=\"0; URL=http:\/\/;URL=javascript:alert\('XSS'\);\">|<DIV STYLE=\"background-image: url\(javascript:alert\('XSS'\)\)\">|<body onload=\"javascript:alert\('XSS'\)\"><\/body>|<table background=\"javascript:alert\('XSS'\)\"><\/table>).*</i){
			$vulnerable++;
			$func->write("| [+] Vul[$vulnerable] [XSS] $url               \n| Post data: $data               ");
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

sub status(){
 my $self = shift;
 return $enabled;
}









1;
