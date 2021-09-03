package Plugins::Tests::Static::checkPUT;

use Uniscan::Http;
use Uniscan::Functions;
use Uniscan::Configure;
	
my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();
my $func = Uniscan::Functions->new();
my $http = Uniscan::Http->new();

sub new {
    my $class    = shift;
    my $self     = {name => "PUT method test", version => 1.2};
	our $enabled  = 0;
    return bless $self, $class;
}


sub execute(){
	my ($self,$url) = @_;

	$func->write("|"." "x99);
	$func->write("|"." "x99);
	$func->write("| ".$conf{'lang141'}.":");
	$func->writeHTMLItem($conf{'lang141'} .":<br>");
    &CheckPut($url);
	}

	
sub CheckPut(){
	my $url = shift;
	my $h = Uniscan::Http->new();
	my $resp = $h->PUT($url."uniscan.txt", "uniscan123 uniscan123");
	$resp = $h->GET($url."uniscan.txt");
	if($resp =~/uniscan123/){
		$vulnerable++;
		$func->write("="x100);
		$func->write("| ". $conf{'lang142'});
		$func->writeHTMLValue($conf{'lang142'});
		$func->write("| [+] Vul: $url/uniscan.txt");
		$func->writeHTMLValue("$url/uniscan.txt");
		$func->write("="x100);
	}
}

sub status(){
 my $self = shift;
 return $enabled;
}



sub clean(){
 my $self = shift;
}

1;

