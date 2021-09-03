package Uniscan::FingerPrint_Server;

use Moose;
use Uniscan::Functions;
use Uniscan::Configure;
use Net::FTP;
use URI;
use Digest::MD5;

use HTTP::Request;
use HTTP::Cookies;
use LWP::UserAgent;
use LWP::Simple;
use LWP::ConnCache;
	
my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();


my $func = Uniscan::Functions->new();

$| = 1;

sub fingerprintServer{
 	my ($self, $target) = @_;
        my $url = &host($target);
        my $i = 0;
	my @nslookup;
	my (@nslookup2,@nslookup_result);
        my ($d,@arq,$lwp,$connect,$version);

##############################################
#  Function PING
##############################################
	$func->write("="x99);
	$func->write("| PING");
	$func->writeHTMLItem("Ping:<br>");
	$func->write("| ".""x99);
	my @ping = `ping -c 4 -w 4 $url`;
	foreach $i (@ping) {
		chomp($i);
		$func->write("| $i");
		$func->writeHTMLValue($i);
	}

##############################################
#  Function TRACEROUTE
##############################################

	$func->write("="x99);
	$func->write("| ". $conf{'lang59'});
	$func->writeHTMLItem($conf{'lang60'} .":<br>");
	$func->write("| ".""x99);
	my @traceroute = `traceroute $url`;
	foreach $i (@traceroute) {
		chomp($i);
		$func->write("| $i");
		$func->writeHTMLValue($i);
	}

##############################################
#  Function NSLOOKUP
##############################################

	$func->write("="x99);
	$func->write("| ". $conf{'lang61'});
	$func->writeHTMLItem($conf{'lang62'} .":<br>");
	$func->write("| ");

	@nslookup = `nslookup -type=MX $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=PX $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=NS $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=A $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=CNAME $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=HINFO $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=PTR $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=SOA $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=TXT $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=WKS $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=ANY $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=MB $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=MINFO $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=MG $url`;
	push(@nslookup2,@nslookup);
	@nslookup = `nslookup -type=MR $url`;
	push(@nslookup2,@nslookup);
	@nslookup_result = &remove(@nslookup2);

	foreach my $i (@nslookup_result) {
		chomp($i);
		$func->write("| ".$i);
		$func->writeHTMLValue($i);
	}

##############################################
#  Function NMAP
##############################################

	$func->write("="x99);
	$func->write("| ". $conf{'lang63'});
	$func->writeHTMLItem($conf{'lang64'} .":<br>");
	$func->write("| ".""x99);
	my @nmap = `nmap -v -A $url`;
	foreach my $i (@nmap) {
		chomp($i);
		$func->write("| $i");
		$func->writeHTMLValue("$i");
	}
	$func->write("="x99);
}


sub host(){
  	my $h = shift;
  	my $url1 = URI->new( $h || return -1 );
  	return $url1->host();
}

##############################################
#  Function remove
#  this function removes repeated elements of 
#  a array
#
#  Param: @array
#  Return: @array
##############################################

sub remove{
   	my @si = @_;
   	my @novo = ();
   	my %ss;
   	foreach my $s (@si)
   	{
        	if (!$ss{$s})
        	{
            		push(@novo, $s);
            		$ss {$s} = 1;
        	}
    	}
    	return (@novo);
}


# code below taken from the project web-sorrow
sub genErrorString{
	my $errorStringGGG = "";
        my $i = 0;
	for($i = 0;$i < 20;$i++){
		$errorStringGGG .= chr((int(rand(93)) + 33)); # random 20 bytes to invoke 404 sometimes 400
	}
	
	$errorStringGGG =~ s/(#|&|\?)//g; #strip anchors and q stings
	return $errorStringGGG;
}

sub matchScan{
	my $checkMatchFromDB = shift;
	my $checkMatch = shift;
	my $matchScanMSG = shift;
	chomp $checkMatchFromDB;
	my @matchScanLineFromDB = split(';',$checkMatchFromDB);
	my $msJustString = $matchScanLineFromDB[0]; #String to find
	my $msMSG = $matchScanLineFromDB[1]; #this is the message printed if it isn't an error
	if($checkMatch =~ /$msJustString/){
		$func->write("| $matchScanMSG: $msMSG");
		$func->writeHTMLValue(" $matchScanMSG: $msMSG");
	}
}

1;
