package Uniscan::Functions;

use Moose;
use Uniscan::Http;
use HTTP::Response;
use Socket;
use threads;
use threads::shared;
use Thread::Queue;
use Thread::Semaphore;
use HTTP::Request;
use LWP::UserAgent;
use Uniscan::Configure;
use strict;
use URI;

our %conf = ( );
our $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();
our $pattern;
my $q = new Thread::Queue;
my $semaphore = Thread::Semaphore->new();
our @list :shared= ( );
##############################################
#  Function GetServerInfo
#  this function write the banner of http server
#
#
#  Param: $url
# 
##############################################


sub GetServerInfo(){
	my ($self, $url) = @_;
	my $http = Uniscan::Http->new();
	my $response = $http->HEAD($url);
	&writeHTMLItem("self", $conf{'lang82'} .":") if($response->server);
	&writeHTMLValue("self", $response->server) if($response->server);
	&write('ae', "| ". $conf{'lang83'} .": ". $response->server) if($response->server);
	
}




##############################################
#  Function GetServerIp
#  this function return the IP of the url
#
#
#  Param: $url
#  Return: ip
##############################################


sub GetServerIp(){
	my ($self, $url) = @_;
	$url =~ s/https?:\/\///g if($url =~/https?:\/\//);
	$url = substr($url, 0, index($url, '/'));
	$url = substr($url, 0, index($url, ':')) if($url =~/:/); 
	return(join(".", unpack("C4", (gethostbyname($url))[4])));
}




##############################################
#  Function Check
#  this function threadnize the function 
#  GetResponse
#
#  Param: $url, $textfile
#  Return: nothing 
##############################################


sub Check(){
	my ($self, $url, $txtfile) = @_;
	$semaphore->down();
	@list = ( );
	$semaphore->up();
	open(my $file, "<", $txtfile) or die "$!\n";
	my @directory = <$file>;
	close($file);
	
	
	foreach my $dir (@directory){
		chomp($dir);
		$q->enqueue($url.$dir);
	}
	my $x =0;
	my @threads = ();
	while($q->pending() && $x <  $conf{'max_threads'}){
		$x++;
		push @threads, threads->create(\&GetResponse);
	}

	
	sleep(2);
	
	foreach my $running (@threads) {
		$running->join();
		print "[*] ". $conf{'lang65'} .": ". $q->pending ."       \r";
	}
return @list;
}



##############################################
#  Function GetResponse
#  this function check the response code of a
#  request
#
#  Param: $url
#  Return: nothing 
##############################################


sub GetResponse(){
	
	while($q->pending()){
		my $url1 = $q->dequeue;
		my $http = Uniscan::Http->new();
		next if(not defined $url1);
		print "[*] ". $conf{'lang65'} .": ". $q->pending ."       \r";
			my $response=$http->HEAD($url1);
			if($response){
				if($response->code =~ $conf{'code'}){
					$semaphore->down();
					push(@list, $url1);
					$semaphore->up();
					print " "x40 . "\r";
					&write('', "| [+] ". $conf{'lang84'} .": " .$response->code." URL: $url1");
					&writeHTMLValue("", $conf{'lang84'} .": " .$response->code." URL: $url1");
				}
			}
			$response = 0;
	}
	$q->enqueue(undef);
}


##############################################
#  Function write
#  this function print any text on screen and
#  in log file
#
#  Param: $url
#  Return: nothing 
##############################################


sub write(){
	my ($self, $text) = @_;
	$semaphore->down();
	open(my $log, ">>". $conf{'log_file'}) or die "$!\n";
	print $log "$text\n";
	close($log);
	print "$text\n";
	$semaphore->up();
}



##############################################
#  Function INotPage
#  try detect a pattern of a 404 page
#  
#
#  Param: $url
#  Return: nothing 
##############################################


sub INotPage(){
	my ($self, $url) = @_;
	$url .= "/uniscan". int(rand(10000)) ."uniscan/";
	my $h = Uniscan::Http->new();
	my $content = $h->GET($url);
	if($content =~ /404/){
		$pattern = substr($content, 0, index($content, "404")+3);
	}
	else{
		$content =~/<title>(.+)<\/title>/i;
		$pattern = $1;
	}
	$pattern = "not found|não encontrada|página solicitada não existe|could not be found" if(!$pattern);
	$h = "";
	return $pattern;
}

##############################################
#  Function get_file
#  this function return the path and file of 
#  a page
#
#  Param: $url
#  Return: $path/file 
##############################################

sub get_file(){
	my ($self, $url1) = @_;
	substr($url1,0,7) = "" if($url1 =~/http:\/\//);
	substr($url1,0,8) = "" if($url1 =~/https:\/\//);
	substr($url1, index($url1, '?'), length($url1)) = "" if($url1 =~/\?/);
	if($url1 =~ /\//){
		$url1 = substr($url1, index($url1, '/'), length($url1)) if(length($url1) != index($url1, '/'));
		if($url1 =~ /\?/){
			$url1 = substr($url1, 0, index($url1, '?'));
		}
		return $url1;
	}
	elsif($url1=~/\?/){
		$url1 = substr($url1, 0, index($url1, '?'));
		return $url1;
	}
	else {
		return $url1;
	}
}


##############################################
#  Function get_url
#  this function return the url without file
# 
#
#  Param: $url
#  Return: $url
##############################################
sub get_url(){
	my ($self, $url) = @_;
	if($url =~/http:\/\//){
		$url =~s/http:\/\///g;
		$url = "http://" . substr($url, 0, index($url, '/'));
		return $url;
	}
	if($url =~/https:\/\//){
		$url =~s/https:\/\///g;
		$url = "https://" . substr($url, 0, index($url, '/'));
		return $url;
	}
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
            		$ss{$s} = 1;
        	}
    	}
    	return @novo;
}


##############################################
# Function check_url
# this function check if one url is in correct
# format
#
# Param: $url
# Return: nothing
##############################################

sub check_url(){
	my ($self, $url1) = @_;
	if(!$url1 || $url1 !~ /https?:\/\/.+\//){
		printf("The url %s is not in correct format\n", $url1);
		exit();
	}
}


##############################################
# Function help
# this function show the help
#
#
# Param: nothing
# Return: nothing
##############################################

sub help(){
	my $self = shift;
	print 	$conf{'lang66'} .":\n".
		"\t-h \t". $conf{'lang67'} ."\n".
		"\t-u \t". $conf{'lang68'} ."\n".
		"\t-f \t". $conf{'lang69'} ."\n".
		"\t-b \t". $conf{'lang70'} ."\n".
		"\t-q \t". $conf{'lang71'} ."\n".
		"\t-w \t". $conf{'lang72'} ."\n".
		"\t-e \t". $conf{'lang73'} ."\n".
		"\t-d \t". $conf{'lang74'} ."\n".
		"\t-s \t". $conf{'lang75'} ."\n".
		"\t-r \t". $conf{'lang76'} ."\n".
		"\t-i \t". $conf{'lang77'} ."\n".
		"\t-o \t". $conf{'lang78'} ."\n".
		"\t-g \t". $conf{'lang79'} ."\n".
		"\t-j \t". $conf{'lang80'} ."\n".
		"\n".
		$conf{'lang81'} .": \n".
		"[1] perl $0 -u http://www.example.com/ -qweds\n".
		"[2] perl $0 -f sites.txt -bqweds\n".
		"[3] perl $0 -i uniscan\n".
		"[4] perl $0 -i \"ip:xxx.xxx.xxx.xxx\"\n".
		"[5] perl $0 -o \"inurl:test\"\n".
		"[6] perl $0 -u https://www.example.com/ -r\n\n\n";
	exit();
}



##############################################
#  Function banner
#  this function show the scanner banner
#
#  Param: nothing
#  Return: nothing
##############################################


sub banner(){
	my $self = shift;
	&write("a", "####################################\n# Uniscan project                  #\n# http://uniscan.sourceforge.net/  #\n####################################\nV. ". $conf{'version'} ."\n\n");
}



##############################################
#  Function date
#  this function return current date
#
#
#  Param: @array
#  Return: @array
##############################################

sub date{
	my $self = shift;
	my $c = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	$year += 1900;
	$mon++;
	&writeHTMLCategory("self", $conf{'lang85'});
	&writeHTMLItem("self", $conf{'lang86'} .":") if($c == 0);
	&writeHTMLItem("self", $conf{'lang87'} .":") if($c == 1);
	&writeHTMLValue("$self", "$mday/$mon/$year $hour:$min:$sec");
	&writeHTMLCategoryEnd();
	return "$mday-$mon-$year $hour:$min:$sec";
}


sub CheckUpdate(){
	my $self = shift;
	my $h = Uniscan::Http->new();
	my $response = $h->GET("http://uniscan.sourceforge.net/version.txt");
	chomp $response;
	if($response ne $conf{'version'} && $response =~ /^\d+[\.\d+]+$/){
		&write("self", $conf{'lang88'} ." $response ". $conf{'lang89'});
		&write("self", $conf{'lang90'} ." http://uniscan.sourceforge.net/\n\n");
		update() if($conf{'autoupdate'} == 1);
		
	}
}


sub DoLogin(){
	my $self = shift();
	if($conf{'use_cookie_auth'} == 1){
		my $h = Uniscan::Http->new();
		my $resp = 0;
		$resp = $h->GET($conf{'url_cookie_auth'});
		$conf{'input_cookie_login'} =~s/"//g;
		
		$resp = $h->POST($conf{'url_cookie_auth'}, $conf{'input_cookie_login'}) if($conf{'method_cookie_login'} eq "POST");
		$resp = $h->GET($conf{'url_cookie_auth'}.'?'.$conf{'input_cookie_login'}) if($conf{'method_cookie_login'} eq "GET");

	}
}

sub CheckRedirect(){
	my ($self, $url) = @_;
	use LWP::UserAgent;
	use HTTP::Headers;
	my $ua = LWP::UserAgent->new;
	my $request  = HTTP::Request->new( HEAD => $url);
	my $response = $ua->request($request);
	if ( $response->is_success and $response->previous ){
		$url =~ /https?:\/\/(.+)\//;
		my $u1 = $1;
		$response->request->uri =~ /https?:\/\/(.+)\//;
		my $u2 = $1;
		$url =~ s/$u1/$u2/g;
		&write("ae", "="x99);
		&writeHTMLItem("self", $conf{'lang91'} .":");
		&writeHTMLValue("self",  $request->url ." ". $conf{'lang92'} ." " . $url);
		&writeHTMLItem("self", $conf{'lang93'} .":");
		&writeHTMLValue("self",  $url);
		&write("ae", "| [*] ". $request->url ." ". $conf{'lang92'} ." " . $url);
		&write("ae", "| [*] ". $conf{'lang93'} .": $url");
	}
	return $url;
}

sub createHTML(){
	$semaphore->down();
	open(my $html, ">", $conf{'html_report'});
	print $html '	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
			<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<meta http-equiv="refresh" content="10">
			<title>Uniscan Report</title>
			<link href="css.css" rel="stylesheet" />
			</head>
			<body>
			<center><img src="images/logo.png"></center><br />
			';
	close($html);
	$semaphore->up();
}

sub createHTMLRedirect(){
	my $file = shift;
	$semaphore->down();
	open(my $html, ">", $conf{'html_report'});
	print $html '	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
			<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
			<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
			<meta http-equiv="refresh" content="0; url='. $file .'">
			<title>Uniscan Report</title>
			<link href="css.css" rel="stylesheet" />
			</head>
			<body>
			<center><img src="images/logo.png"></center><br>
			';
	close($html);
	$semaphore->up();
}

sub writeHTMLCategory(){
	my ($self, $content) = @_;
	$semaphore->down();
	open(my $html, ">>", $conf{'html_report'});
	print $html "<br><br><fieldset>\n<legend>$content</legend>\n";
	close($html);
	$semaphore->up();
}

sub writeHTMLCategoryEnd(){
	my ($self, $content) = @_;
	$semaphore->down();
	open(my $html, ">>", $conf{'html_report'});
	print $html "</fieldset>\n";
	close($html);
	$semaphore->up();
}

sub writeHTMLItem(){
	my ($self, $item) = @_;
	$semaphore->down();
	open(my $html, ">>", $conf{'html_report'});
	print $html "<br>$item \n";
	close($html);
	$semaphore->up();
}

sub writeHTMLValue(){
	my ($self, $cont) = @_;
	$cont =~s/\r|\n//g;
	$semaphore->down();
	open(my $html, ">>", $conf{'html_report'});
	print $html "<font id=\"valor\">$cont</font><br>\n";
	close($html);
	$semaphore->up();
}


sub writeHTMLVul(){
	my ($self, $cont) = @_;
	$semaphore->down();
	open(my $html, ">>", $conf{'html_report'});
	print $html "<a name='$cont' id='$cont'></a>";
	print $html "\n<!--$cont-->\n";
	close($html);
	$semaphore->up();
}



sub writeHTMLEnd(){
	my $self = shift;
	$semaphore->down();
	open(my $html, "<", $conf{'html_report'});
	my @con = <$html>;
	close($html);
	$semaphore->up();
	
	my $content = "@con";
	$content =~ s/<meta http-equiv="refresh" content="10">//g;
	$semaphore->down();
	open($html, ">", $conf{'html_report'});
	print $html $content . "\n</body></html>";
	close($html);
	$semaphore->up();
}

sub MoveReport(){
	my ($self, $url) = @_;
	my $msg = $conf{'html_report'};
	$url = &host($url);
	$url .= ".html";
	$msg =~ s/uniscan\.html/$url/g;
	system("mv ". $conf{'html_report'} . " " . $msg);
	&write(" ", $conf{'lang94'} .": $msg");
	&createHTMLRedirect($url);
	
}


sub host(){
  	my $h = shift;
  	my $url1 = URI->new( $h || return -1 );
  	return $url1->host();
}


sub update(){
	#backup old version
	if($^O ne "MSWin32"){
		system("rm -rf ../uniscan-old") if(-d '../uniscan-old');
		system("mkdir ../uniscan-old") if(!-d '../uniscan-old');
		system("cp -R * ../uniscan-old/") if(-d '../uniscan-old');
		#download and overwrite files
		system("git clone git://git.code.sf.net/p/uniscan/code uniscan-code");
		system("cp -R uniscan-code/* .; rm -rf uniscan-code/") if(-d "uniscan-code");
		&write("", "| [*] ". $conf{'lang95'});
		exit();
	}
	else{
		&write(" ", $conf{'lang96'});
		exit();
	}
}

1;


