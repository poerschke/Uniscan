package Plugins::Crawler::codeDisclosure;

use Uniscan::Functions;
use Thread::Semaphore;
use Uniscan::Configure;
	
my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();
my $func = Uniscan::Functions->new();
our %source : shared = ();
my $semaphore = Thread::Semaphore->new();

sub new {
    my $class    = shift;
    my $self     = {name => "Code Disclosure", version => 1.1};
	our $enabled = 1;
    return bless $self, $class;
}

sub execute {
	my $self = shift;
	my $url = shift;
	my $content = shift;
	my @codes = ('<\?php', '#include <', '#!\/usr', '#!\/bin', 'import java\.', 'public class .+\{', '<\%.+\%>', '<asp:', 'package\s\w+\;');

	
	foreach my $code (@codes){
		if($content =~ /$code/i){
			$semaphore->down();
			$source{$url}++;
			$semaphore->up();
		}
	}
}


sub showResults(){
	my $self = shift;
	$func->write("|\n| ". $conf{'lang101'} .":");
	$func->writeHTMLItem($conf{'lang101'} .":<br>");
	foreach my $url (keys %source){
		$func->write("| [+] ". $conf{'lang102'} .": ". $url) if($source{$url});
		$func->writeHTMLValue($conf{'lang102'} .": ". $url) if($source{$url});
		$func->writeHTMLVul("SOURCECODE") if($source{$url});
	}
}

sub getResults(){
	my $self = shift;
	return %source;
}

sub clean(){
	my $self = shift;
	%source = ();
}

sub status(){
	my $self = shift;
	return $enabled;
}

1;
