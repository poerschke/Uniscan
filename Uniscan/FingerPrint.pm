package Uniscan::FingerPrint;

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

my $func = Uniscan::Functions->new();
my $encontrou = 0;
my %existe = ();
my $wordpress = 0;
my $joomla = 0;
my $drupal = 0;

my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();



sub fingerprint{
 	my ($self, $target) = @_;
        my $url = &host($target);
        my $i = 0;
	my @nslookup;
	my (@nslookup2,@nslookup_result);
        my ($d,@arq,$lwp,$connect,$version);
        my (@in,$left,$right);

##############################################
#  Function METHOD ENABLED
##############################################

	$func->write("="x99);
	$func->write("| " . $conf{'lang39'});
	$func->writeHTMLItem($conf{'lang40'} .":<br>");
	$func->write("| ".""x99);
	my $host = $url;
	my $path = "pdUsmmdhVC";
	my $port = 80 ; # webserver port
	my $sock = IO::Socket::INET->new(PeerAddr => $host,
					PeerPort => $port,
					Proto    => 'tcp',
					Timeout => 30) or return;
	print $sock "PUT /".$path." HTTP/1.1\r\n" ;
	print $sock "Host: ".$host."\r\n" ;
	print $sock "Connection:close\r\n" ;
	print $sock "\r\n\r\n" ;
 
        while(<$sock>){
            push (@in, $_);
        }
        close($sock) ;

	foreach my $line (@in){
		if ($line =~ /^Allow: /){
			($left,$right)=split(/\:/,$line);
			$right =~ s/ |\r|\n//g; 
			$func->write("| ".$right);
			$func->writeHTMLValue($right);
			$func->write("="x99);
		}
	}
#code below taken from the project web-sorrow
##############################################
#  SERVICES WEB
##############################################

	my %existe_ = ();
	my $ua = LWP::UserAgent->new(conn_cache => 1);
	$ua->conn_cache(LWP::ConnCache->new); # use connection cacheing (faster)
	$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5) Gecko/20031027");
	$func->write("="x99);
	$func->write("| ". $conf{'lang42'});
	$func->writeHTMLItem($conf{'lang42'} . ":<br>");
	$func->write("| ".""x99);
	open(webServicesDB, "<", "DB/web-services.db");
	my @parsewebServicesdb = <webServicesDB>;
	my $webServicesTestPage = $ua->get("http://$url/");
	my @webServicesStringMsg;
	foreach my $lineIDK (@parsewebServicesdb){
		push(@webServicesStringMsg, $lineIDK);
	}

	foreach my $ServiceString (@webServicesStringMsg){
		&matchScan($ServiceString,$webServicesTestPage->content,"Web service Found");
	}
	close(webServicesDB);
	
#code below taken from the project web-sorrow
##############################################
#  FAVICON
##############################################

	$ua = LWP::UserAgent->new(conn_cache => 1);
	$ua->conn_cache(LWP::ConnCache->new); # use connection cacheing (faster)
	$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5) Gecko/20031027");
	$func->write("="x99);
	$func->write("| FAVICON.ICO");
	$func->writeHTMLItem("Favicon.ico ". $conf{'lang44'} .":<br>");
	$func->write("| ".""x99);
	my $favicon = $ua->get("http://$url/favicon.ico");
	if($favicon->is_success){
		my $MD5 = Digest::MD5->new;
		$MD5->add($favicon->content);
		my $checksum = $MD5->hexdigest;
		open(faviconMD5DB, "<", "DB/favicon.db");
		my @faviconMD5db = <faviconMD5DB>;
		my @faviconMD5StringMsg; # split DB by line
		foreach my $lineIDK (@faviconMD5db){
			push(@faviconMD5StringMsg, $lineIDK);
		}
		foreach my $faviconMD5String (@faviconMD5StringMsg){

			&matchScan($faviconMD5String,$checksum,"Web service Found (favicon.ico)");
		}
		close(faviconMD5DB);
	}
#code below taken from the project web-sorrow
##############################################
#  INFO ERROR BEGGING
##############################################

	$ua = LWP::UserAgent->new(conn_cache => 1);
	$ua->conn_cache(LWP::ConnCache->new); # use connection cacheing (faster)
	$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5) Gecko/20031027");
	$func->write("="x99);
	$func->write("| ". $conf{'lang45'});
	$func->writeHTMLItem($conf{'lang46'} .":<br>");
	$func->write("| ".""x99);
	my $getErrorString = &genErrorString();
	my $_404responseGet = $ua->get("http://$url/$getErrorString");
	&checkError($_404responseGet);
	my $postErrorString = &genErrorString();
	my $_404responsePost = $ua->post("http://$url/$postErrorString");
	&checkError($_404responsePost);

#code below taken from the project web-sorrow
##############################################
#  TYPE ERROR
##############################################

	my %existe_E = ();
	$ua = LWP::UserAgent->new(conn_cache => 1);
	$ua->conn_cache(LWP::ConnCache->new); # use connection cacheing (faster)
	$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5) Gecko/20031027");
	$func->write("="x99);
	$func->write("| ". $conf{'lang47'});
	$func->writeHTMLItem($conf{'lang48'} .":<br>");
	$func->write("| ".""x99);
	# Some servers just give you a 200 with every req. lets see
	my @webExtentions = ('.php','.html','.htm','.aspx','.asp','.jsp','.cgi');
	foreach my $Extention (@webExtentions){
		my $testErrorString = &genErrorString();
		my $check200 = $ua->get("http://$url/$testErrorString" . $Extention);
		if($check200->is_success){
			if(!$existe_E{$Extention}){
				$func->write("| http://$url/$testErrorString" . $Extention . " ". $conf{'lang49'} .": " . $check200->code . " ". $conf{'lang50'} .": $Extention " . $conf{'lang51'});
				$func->writeHTMLValue("http://$url/$testErrorString$Extention ". $conf{'lang49'} .":" . $check200->code . " ". $conf{'lang50'} .": $Extention ". $conf{'lang51'});
				$existe_E{$Extention} = 1;
			}
		}
	}
#code below taken from the project web-sorrow
##############################################
#  SERVER MOBILE
##############################################

	$ua = LWP::UserAgent->new(conn_cache => 1);
	$ua->conn_cache(LWP::ConnCache->new); # use connection cacheing (faster)
	$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5) Gecko/20031027");
	$func->write("="x99);
	$func->write("| ". $conf{'lang52'});
	$func->writeHTMLItem($conf{'lang53'} .":<br>");
	$func->write("| ".""x99);
	#does the site have a mobile page?
	my $MobileUA = LWP::UserAgent->new;
	$MobileUA->agent('Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0');
	my $mobilePage = $MobileUA->get("http://$url/");
	my $regularPage = $ua->get("http://$url/");
	unless($mobilePage->content() eq $regularPage->content()){
		$func->write("| ". $conf{'lang54'});
		$func->writeHTMLValue($conf{'lang54'});
	}
#code below taken from the project web-sorrow
##############################################
#  LANGUAGE
##############################################

	my %existe_L = ();
	$ua = LWP::UserAgent->new(conn_cache => 1);
	$ua->conn_cache(LWP::ConnCache->new); # use connection cacheing (faster)
	$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5) Gecko/20031027");
	$func->write("="x99);
	$func->write("| ". $conf{'lang55'});
	$func->writeHTMLItem($conf{'lang56'} .":<br>");
	$func->write("| ".""x99);
	# laguage checks
	my $LangReq = $ua->get($target);
	my @langSpaceSplit = split(/ / ,$LangReq->decoded_content);
	my $langString = 'lang=';
	my @langGate;
	foreach my $lineIDK (@langSpaceSplit){
		if($lineIDK =~ /$langString('|").*?('|")/i){
			while($lineIDK =~ "\t"){ #make pretty
				$lineIDK =~ s/\t//sg;
			}
			while($lineIDK =~ /(<|>)/i){ #prevent html from sliping in
				chop $lineIDK;
			}
			unless($lineIDK =~ /lang=('|")('|")/){ # empty?
				if(!$existe_L{$lineIDK}){
					$func->write("| $lineIDK");
					$func->writeHTMLValue($lineIDK);
					$existe_L{$lineIDK} = 1;
				}
			}
		}
	}
#code below taken from the project web-sorrow
##############################################
#  INTERESTING STRINGS IN HTML
##############################################

	my %existe_I = ();
	$ua = LWP::UserAgent->new(conn_cache => 1);
	$ua->conn_cache(LWP::ConnCache->new); # use connection cacheing (faster)
	$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5) Gecko/20031027");
	$func->write("="x99);
	$func->write("| ". $conf{'lang57'});
	$func->writeHTMLItem($conf{'lang58'} .":<br>");
	$func->write("| ".""x99);
	my @interestingStings = ('/cgi-bin','password','passwd','admin','database','payment','bank','account','twitter.com','facebook.com','login','@.*?(com|org|net|tv|uk|au|edu|mil|gov)','<!--#');
	my $mineIndex = $ua->get($target);
	foreach my $checkInterestingSting (@interestingStings){
		my @IndexData = split(/</,$mineIndex->decoded_content);
		foreach my $splitIndex (@IndexData){
			if($splitIndex =~ /$checkInterestingSting/i){
				while($splitIndex =~ /(\n|\t|  )/){
					$splitIndex =~ s/\n/ /g;
					$splitIndex=~ s/\t//g;
					$splitIndex=~ s/  / /g;
				}
				# the split chops off < so i just stick it in there to make it look pretty
				#print "+ interesting text found in: <$splitIndex\n";
				if(!$existe_I{$splitIndex}){
					$splitIndex =~ s/\n/\n| /g;
					$splitIndex =~ s/\r//g;
					$func->write("| $splitIndex") if($splitIndex);
					$func->writeHTMLValue($splitIndex) if($splitIndex);
					$existe_I{$splitIndex} = 1;
				}
			}
			
		}
	}

##############################################
#  Function WHOIS
#  this function show info server
##############################################

	$func->write("="x99);
	$func->write("| WHOIS");
	$func->writeHTMLItem("Whois:<br>");
	$func->write("| ".""x99);
	my @connect = `whois -H $url`;
	foreach my $d (@connect){
		$d =~s/<BR>//g;
		$d =~s/<br>//g;
		push(@arq,$d);
	}
	foreach my $d (@arq){
		$d =~s/Get Noticed on the Internet!  Increase visibility for this domain name by listing it at www.whoisbusinesslistings.com//g;
		$d =~s/=-=-=-=//g;
		$d =~s/<a href="\?dominio=.+&resposta_completa=ok">mais detalhes<\/a>//g;
		$d =~s/The data in this whois database is provided to you for information//g;
		$d =~s/purposes only, that is, to assist you in obtaining information about or//g;
		$d =~s/related to a domain name registration record. We make this information//g;
		$d =~s/available \"as is,\" and do not guarantee its accuracy. By submitting a//g;
		$d =~s/whois query, you agree that you will use this data only for lawful//g;
		$d =~s/purposes and that, under no circumstances will you use this data to: \(1\)//g;
		$d =~s/enable high volume, automated, electronic processes that stress or load//g;
		$d =~s/this whois database system providing you this information; or \(2\) allow,//g;
		$d =~s/enable, or otherwise support the transmission of mass unsolicited,//g;
		$d =~s/commercial advertising or solicitations via direct mail, electronic//g;
		$d =~s/mail, or by telephone. The compilation, repackaging, dissemination or//g;
		$d =~s/other use of this data is expressly prohibited without prior written//g;
		$d =~s/consent from us.  //g;
		$d =~s/We reserve the right to modify these terms at any time. By submitting //g;
		$d =~s/this query, you agree to abide by these terms.//g;
		$d =~s/The Registry database contains ONLY .COM, .NET, .EDU domains and//g;
		$d =~s/Registrars.------------------------------------------------------------------------------- =-=-=-=//g;
		$d =~s/Services\' \(\"VeriSign\"\) Whois database is provided by VeriSign for to: \(1\) allow, enable, or otherwise support the transmission of mass //g;
		$d =~s///g;
		$d =~s/or facsimile; or \(2\) enable high volume, automated, electronic processes //g;
		$d =~s/that apply to VeriSign \(or its computer systems\). The compilation,//g;
		$d =~s/Domain names in the .com and .net domains can now be registered//g;
		$d =~s/with many different competing registrars. Go to http:\/\/www.internic.net//g;
		$d =~s/for detailed information.//g;
		$d =~s/NOTICE: The expiration date displayed in this record is the date the //g;
		$d =~s/registrar\'s sponsorship of the domain name registration in the registry is //g;
		$d =~s/currently set to expire. This date does not necessarily reflect the expiration //g;
		$d =~s/date of the domain name registrant\'s agreement with the sponsoring //g;
		$d =~s/registrar.  Users may consult the sponsoring registrar\'s Whois database to //g;
		$d =~s/view the registrar\'s reported date of expiration for this registration.//g;
		$d =~s/TERMS OF USE: You are not authorized to access or query our Whois //g;
		$d =~s/database through the use of electronic processes that are high-volume and //g;
		$d =~s/automated except as reasonably necessary to register domain names or //g;
		$d =~s/modify existing registrations; the Data in VeriSign Global Registry //g;
		$d =~s/Services\' \(\"VeriSign\"\) Whois database is provided by VeriSign for //g;
		$d =~s/information purposes only, and to assist persons in obtaining information //g;
		$d =~s/about or related to a domain name registration record. VeriSign does not //g;
		$d =~s/guarantee its accuracy. By submitting a Whois query, you agree to abide //g;
		$d =~s/by the following terms of use: You agree that you may use this Data only //g;
		$d =~s/for lawful purposes and that under no circumstances will you use this Data //g;
		$d =~s/to: \(1\) allow, enable, or otherwise support the transmission of mass //g;
		$d =~s/unsolicited, commercial advertising or solicitations via e-mail, telephone, //g;
		$d =~s/or facsimile; or \(2\) enable high volume, automated, electronic processes //g;
		$d =~s/that apply to VeriSign \(or its computer systems\). The compilation, //g;
		$d =~s/repackaging, dissemination or other use of this Data is expressly //g;
		$d =~s/prohibited without the prior written consent of VeriSign. You agree not to //g;
		$d =~s/use electronic processes that are automated and high-volume to access or //g;
		$d =~s/query the Whois database except as reasonably necessary to register //g;
		$d =~s/domain names or modify existing registrations. VeriSign reserves the right //g;
		$d =~s/to restrict your access to the Whois database in its sole discretion to ensure //g;
		$d =~s/operational stability.  VeriSign may restrict or terminate your access to the //g;
		$d =~s/Whois database for failure to abide by these terms of use. VeriSign //g;
		$d =~s/reserves the right to modify these terms at any time. //g;
		$d =~s/<form method=get>//g;
		$d =~s/<font size=\"1\" face=\"Verdana, Arial, Helvetica, sans-serif\">//g;
		$d =~s/<input type=text name=dominio size=30>//g;
		$d =~s/<input type=submit value=Consultar>//g;
		$d =~s/<\/font>//g;
		$d =~s/<\/form>//g;
		$d =~s/<font size=\"1\" face=\"Verdana, Arial, Helvetica, sans-serif\">//g;
		$d =~s/<\/font>//g;
		$d =~s/<HR>//g;
		$d =~s/<font size=\"1\" face=\"Verdana, Arial, Helvetica, sans-serif\"><b>Resposta simplificada:<\/b>//g;
		$d =~s///g;
		$d =~s/<a href=\"\?dominio=portalcplusplus.com.br\&resposta_completa=ok\">mais detalhes<\/a>//g;
		$d =~s///g;
		$d =~s/O Domínio <b>//g;
		$d =~s/portalcplusplus.com.br<\/b>//g;
		$d =~s/<b><img src=registrado.jpg width=32 height=32 align=absmiddle> <font color=#FF0000 size=1 face=Verdana, Arial, Helvetica, sans-serif>DOMINIO REGISTRADO<\/font><\/b><\/font>//g;
		$d =~s///g;
		$d =~s/<HR>//g;
		$d =~s/<font size=\"1\" face=\"Verdana, Arial, Helvetica, sans-serif\"><b>Resposta completa:<\/b>//g;
		$d =~s/<b>Resposta simplificada:<\/b>//g;
		$d =~s/<b>Resposta completa:<\/b>//g;
		$d =~s/<b><img src=registrado.jpg width=32 height=32 align=absmiddle> <font color=#FF0000 size=1 face=Verdana, Arial, Helvetica, sans-serif>DOMINIO REGISTRADO<\/b>//g;
		if($d =~/O (.*) <b>/){
			$d =~s/O $1 <b>//g;
		}
		$d =~ s/\n\n//g;
		$d =~s/\n/\n| /g;
		#chomp($d);
		$func->write("| $d");
		$d =~ s/\|//g;
		$func->writeHTMLValue($d);
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

##############################################
#  Function write
#  this function write a text in a file
#
#  Param: $file_name, @content
#  Return: nothing
##############################################

sub write(){
	my ($filtxt, @content) = @_;
	open(my $a, ">>", $filtxt) or die "$!\n";
	foreach(@content){
		print $a "| $_";
	}
	close($a);
}
#code below taken from the project web-sorrow
sub genErrorString{
	my $errorStringGGG = "";
        my $i = 0;
	for($i = 0;$i < 20;$i++){
		$errorStringGGG .= chr((int(rand(93)) + 33)); # random 20 bytes to invoke 404 sometimes 400
	}
	$errorStringGGG =~ s/(#|&|\?)//g; #strip anchors and q stings
	return $errorStringGGG;
}
#code below taken from the project web-sorrow
sub matchScan{
	my $checkMatchFromDB = shift;
	my $checkMatch = shift;
	my $matchScanMSG = shift;
	chomp $checkMatchFromDB;
	my @matchScanLineFromDB = split(';',$checkMatchFromDB);
	my $msJustString = $matchScanLineFromDB[0]; #String to find
	my $msMSG = $matchScanLineFromDB[1]; #this is the message printed if it isn't an error
	if($checkMatch =~ /$msJustString/){
		$matchScanMSG =~ s/\r|\n//g;
		$msMSG =~ s/\r|\n//g;
		$func->write("| $matchScanMSG: $msMSG");
		$func->writeHTMLValue("$matchScanMSG: $msMSG");
		$drupal = 1 if($msMSG =~ /drupal/i);
		$joomla = 1 if($msMSG =~ /joomla/i);
		$wordpress = 1 if($msMSG =~ /wordpress/i);
	}
}
#code below taken from the project web-sorrow
sub checkError{
	my $_404response = shift;
	if($_404response->is_error) {
		#$func->write("| [+] Error Begging " . $_404response->code . " - ");
		my $siteHTML = $_404response->decoded_content;
		### strip html tags and make pretty [very close to perfectly]
		$siteHTML =~ s/<script.*?<\/script>//sgi;
		$siteHTML =~ s/<style.*?<\/style>//sgi;
		$siteHTML =~ s/<(?!--)[^'">]*"[^"]*"/</sgi;
		$siteHTML =~ s/<(?!--)[^'">]*'[^']*'/</sgi;
		$siteHTML =~ s/<(?!--)[^">]*>//sgi;
		$siteHTML =~ s/<!--.*?-->//sgi;
		$siteHTML =~ s/<.*?>//sgi;
		$siteHTML =~ s/\n/ /sg;
		while($siteHTML =~ "  "){
			$siteHTML =~ s/  / /g;
		}
		while($siteHTML =~ "\t"){
			$siteHTML =~ s/\t//sg;
		}
		my $siteNaked = $siteHTML;
		if(length($siteNaked) < 1000){
			$func->write("| $siteNaked");
			$func->writeHTMLValue($siteNaked);
		} 
	}
}
#code below taken from the project web-sorrow
##############################################
#  BANNER GRABING
##############################################

sub bannergrabing(){

	my ($self, $target) = @_;
	%existe = ();
	$func->write("| ". $conf{'lang35'} .": ");
	$func->writeHTMLItem($conf{'lang36'} .":<br>");
	my $ua = LWP::UserAgent->new(conn_cache => 1);
	$ua->conn_cache(LWP::ConnCache->new); # use connection cacheing (faster)
	$ua->agent("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.5) Gecko/20031027");
	my @checkHeaders = ('x-meta-generator:','x-meta-framework:','x-meta-originator:','x-aspnet-version:','www-authenticate:','x-xss.*:', 'refresh:', 'location:');
	my $resP = $ua->get($target);
	my $url = &host($target);
	my $headers = $resP->as_string();
	my @headersChop = split("\n\n", $headers);
	my @headers = split("\n", $headersChop[0]);
	foreach my $HString (@headers){
		foreach my $checkSingleHeader (@checkHeaders){
			if($HString =~ /$checkSingleHeader/i){
				if(!$existe{$HString}){
					$func->write("| $HString");
					$func->writeHTMLValue($HString);
					$existe{$HString} = 1;
					$wordpress = 1 if($HString =~ /wordpress/i);
					$drupal = 1 if($HString =~ /drupal/i);
					$joomla = 1 if($HString =~ /joomla/i);
				}
			}
		}
	}
	if($joomla == 1){
		$func->write("| ". $conf{'lang37'} .": ");
		$func->writeHTMLValue($conf{'lang37'} .":<br>");
		$func->Check('http://' . $url . "/", "DB/joomla_plugins.db");
	}
	if($wordpress == 1){ 
		$func->write("| ". $conf{'lang38'} .": ");
		$func->writeHTMLValue($conf{'lang38'} .":<br>");
		$func->Check('http://' . $url . "/", "DB/wp_plugins.db");
	}
	if($drupal == 1){ 
		$func->write("| ". $conf{'lang39'} .": ");
		$func->writeHTMLValue($conf{'lang39'} .":<br>");
		$func->Check('http://' . $url . "/", "DB/drupal_plugins.db");
	}
	$func->write("="x99);
}

1;
