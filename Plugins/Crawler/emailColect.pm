package Plugins::Crawler::emailColect;

use Uniscan::Functions;
use Thread::Semaphore;
use Uniscan::Configure;
	
my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();
my $semaphore = Thread::Semaphore->new();
my $func = Uniscan::Functions->new();
our %email : shared = ();

sub new {
	my $class    = shift;
	my $self     = {name => "E-mail Detection", version => 1.1};
	our $enabled = 1;
	return bless $self, $class;
}

sub execute {
    my $self = shift;
	my $url = shift;
	my $content = shift;

	while($content =~m/([a-z\-\_\.\d]+\@[a-z\d\-\.]+\.[a-z{2,4}]+)/g){
		
		$semaphore->down();
		$email{$1}++;
		$semaphore->up();
	}
}


sub showResults(){
	my $self = shift;
	$func->write("|\n| E-mails:");
	$func->writeHTMLItem("E-mails:<br>");
	foreach my $mail (keys %email){
		$func->write("| [+] ". $conf{'lang103'} .": ". $mail) if($email{$mail});
		$func->writeHTMLValue($conf{'lang103'}  .": ". $mail) if($email{$mail});
	}
}

sub getResults(){
	my $self = shift;
	return %email;
}

sub clean(){
	my $self = shift;
	%email = ();
}


sub status(){
	my $self = shift;
	return $enabled;
}

1;
