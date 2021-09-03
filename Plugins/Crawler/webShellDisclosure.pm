package Plugins::Crawler::webShellDisclosure;

use Uniscan::Functions;
use Thread::Semaphore;
use Uniscan::Configure;
	
my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();

my $func = Uniscan::Functions->new();
our %shells : shared = ();
my $semaphore = Thread::Semaphore->new();

my @wb = (	"c99shell<\/title>",
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

sub new {
	my $class    = shift;
	my $self     = {name => "Web Backdoor Disclosure", version => 1.1};
	our $enabled = 1;
	return bless $self, $class;
}

sub execute {
	my $self = shift;
	my $url = shift;
	my $content = shift;

	foreach my $w (@wb){
		if($content =~m/$w/gi){
			$semaphore->down();
			$shells{$url}++;
			$semaphore->up();
		}
	}
}


sub showResults(){
	my $self = shift;
	$func->write("|\n| ". $conf{'lang112'} .":");
	$func->writeHTMLItem($conf{'lang112'} .":<br>");
	foreach my $w (keys %shells){
		$func->write("| [+] ". $conf{'lang113'} .": ". $w) if($shells{$w});
		$func->writeHTMLValue($conf{'lang113'} .": ". $w) if($shells{$w});
		$func->writeHTMLVul("WEBSHELL") if($shells{$w});
	}
}

sub getResults(){
	my $self = shift;
	return %shells;
}

sub clean(){
	my $self = shift;
	%shells = ();
}


sub status(){
	my $self = shift;
	return $enabled;
}

1;

