package Plugins::Crawler::checkUploadForm;

use Uniscan::Functions;
use Thread::Semaphore;
use Uniscan::Configure;
	
my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();


my $func = Uniscan::Functions->new();
our %upload : shared = ();
my $semaphore = Thread::Semaphore->new();

sub new {
    my $class    = shift;
    my $self     = {name => "Upload Form Detect", version => 1.1 };
    our $enabled = 1;
    return bless $self, $class;
}

sub execute {
    my $self = shift;
	my $url = shift;
	my $content = shift;
	while($content =~ m/<input(.+?)>/gi){
		my $params = $1;
		if($params =~ /type *= *"file"/i){
			$semaphore->down();
			$upload{$url}++;
			$semaphore->up();
		}
	}
	

}


sub showResults(){
	my $self = shift;
	$func->write("|\n| ". $conf{'lang99'} .":");
	$func->writeHTMLItem($conf{'lang99'} .":<br>");
	foreach my $url (keys %upload){
		$func->write("| [+] ". $conf{'lang100'} .": ". $url) if($upload{$url});
		$func->writeHTMLValue($conf{'lang100'} .": ". $url) if($upload{$url});
		$func->writeHTMLVul("UPLOADFORM") if($upload{$url});
	}
}

sub getResults(){
	my $self = shift;
	return %upload;
}

sub clean(){
	my $self = shift;
	%upload = ();
}

sub status(){
	my $self = shift;
	return $enabled;
}

1;
