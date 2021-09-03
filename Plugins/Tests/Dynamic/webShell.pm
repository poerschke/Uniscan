package Plugins::Tests::Dynamic::webShell;

use Uniscan::Configure;
use Uniscan::Functions;
use Thread::Queue;
use Uniscan::Http;
use threads;

my $c = Uniscan::Configure->new(conffile => "uniscan.conf");
my $func = Uniscan::Functions->new();
my $http = Uniscan::Http->new();
my $q = new Thread::Queue;

# this plug-in search for web shell files in each directory found by crawler.



sub new {
	my $class    = shift;
	my $self     = {name => "Web Shell Finder", version=>1.3};
	our $enabled  = 1;
	our %conf = ( );
	%conf = $c->loadconf();
	return bless $self, $class;
}


sub execute(){
	my ($self,@urls) = @_;
	my %checks = ();
	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| ".$conf{'lang139'}.":");
	$func->writeHTMLItem($conf{'lang139'}.":<br>");
	my $protocol;
	my @check;
	my @files = (
		"cmd.php",
		"cmd.cgi",
		"cmd.asp",
		"cmd.aspx",
		"cmd.pl",
		"r57.php",
		"c99.php",
		"c.php",
		"shell.php",
		"c99shell.php",
		"r57shell.php",
		"r.php",
		"s.php",
		"mys.php",
		"ps.php",
		"i.php",
		"rem_view.php",
		"remview.php",
		"rem.php",
		"27.9.php",
		"aspxshell.aspx",
		"connect-back.php",
		"erne.php",
		"itsecteam_shell.php",
		"itsecteam.php",
		"jspbd.jsp",
		"jspShell.jsp",
		"knullsh.php",
		"kolang.php",
		"Sst-Sheller.php",
		"SyRiAn.Sh3ll.V7.php",
		"Ani-Shell.php",
		"cmdexec.aspx",
		"2mv2.php",
		"ntdaddy.asp",
		"phpterm.php"
	);


	foreach my $d (@urls){
		$protocol = 'http://' if($d =~/^http:\/\//);
		$protocol = 'https://' if($d =~/^https:\/\//);
		$d =~s/https?:\/\///g;
		substr($d, 0, rindex($d, '/'));
		while($d =~/\//){
			$d = substr($d, 0, rindex($d, '/'));
			foreach my $f (@files){
				my $u = $protocol . $d . '/' . $f;
				if(!$checks{$u}){
					$checks{$u} = 1;
					push(@check, $u) if($u !~/search|procurar|procura|encontrar|find/i);
				 }
			}
		}
	}
	&threadnize(@check);
}

sub clean{
	my $self = shift;
	%backdoors = ();
}



sub status(){
	my $self = shift;
	return $enabled;
}


sub findShell(){
	my @matches = (
		"c99shell<\/title>",
		"C99Shell v",
		"<form method=\"POST\" action=\"cfexec\.cfm\">",
		"<input type=text name=\".CMD\" size=45 value=",
		"<title>awen asp\.net webshell<\/title>",
		"<FORM METHOD=GET ACTION='cmdjsp\.jsp'>",
		"JSP Backdoor Reverse Shell",
		"Simple CGI backdoor by DK",
		"execute command: <input type=\"text\" name=\"c\">",
		"Execute Shell Command",
		"r57shell<\/title>",
		"<title>r57Shell",
		"heroes1412",
		"MyShell",
		"PHP Shell",
		"PHPShell",
		"REMVIEW TOOLS",
		"<title>iTSecTeam<\/title>",
		"JSP Backdoor Reverse Shell",
		"<title>\*  ernealizm  \* <\/title>",
		"<title>JSP Shell<\/title>",
		"<title>Knull Shell<\/title>",
		"<title>.+\- WSO.+</title>",
		"<title>SST Sheller !<\/title>",
		"<title>SyRiAn Sh3ll ",
		"<title>Mini Php Shell",
		"<title>ASPX Shell<\/title>",
		"<title>ZoRBaCK Connect<\/title>",
		"<title>.+Ani\-Shell.+<\/title>",
		"<title>Stored Procedure Execute<\/title>",
		"<title>:: www\.h4ckcity\.org :: Coded By 2MzRp & LocalMan ::<\/title>",
		"<title>PhpShell 2\.0<\/title>",
		"<title>.+NTDaddy.+<\/title>",
		"<title>PHP\-Terminal"
	);

	while($q->pending() > 0){
		my $url1 = $q->dequeue;
		next if(not defined $url1);
		next if($url1 =~/#/g);
		print "[*] ".$conf{'lang65'}.": ". $q->pending  ."       \r";
		my $result = $http->GET($url1);
		foreach my $mat (@matches){
			if($result =~ m/$mat/gi){
				$func->write("| [+] ".$conf{'lang140'}.": $url1");
				$func->writeHTMLValue($conf{'lang140'}.": $url1");
				$func->writeHTMLVul("WEBSHELL");
			}
		}
	}
	$q->enqueue(undef);
}

sub threadnize(){
	my @tests = @_;
	foreach my $test (@tests){
		$q->enqueue($test) if($test);
	} 
	my $x=0;
	my @threads = ();
	while($q->pending() && $x <= $conf{'max_threads'}-1){
		push @threads, threads->new(\&findShell);
		$x++;
	}

	sleep(2);
	foreach my $running (@threads) {
		$running->join();
		print "[*] ".$conf{'lang65'}.": ". $q->pending  ."       \r";
	}
	@threads = ();
}



1;
