package Uniscan::Functions;

use Moose;
use Uniscan::Http;
use HTTP::Response;
use Socket;
use threads;
use threads::shared;
use Thread::Queue;
use HTTP::Request;
use LWP::UserAgent;
use Uniscan::Configure;
use strict;


our %conf = ( );
our $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();
our $pattern;
our @list : shared = ( );
our $q :shared = new Thread::Queue;

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
	&write('ae', "| Server: ". $response->server) if($response->server);	
}




##############################################
#  Function GetServerIp
#  this function return the IP of the url
#
#
#  Param: $url
#  Return: $ip
##############################################


sub GetServerIp(){
	my ($self, $url) = @_;
	$url =~ s/http:\/\///g if($url =~/http:\/\//);
	$url =~ s/https:\/\///g if($url =~/https:\/\//);
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
	@list = ( );
	open(my $file, "<$txtfile") or die "$!\n";
	my @directory = <$file>;
	close($file);
	
	
	foreach my $dir (@directory){
		chomp($dir);
		$q->enqueue($url.$dir);
	}

	our @threads = threads->list();
        our $code : shared = 0;
	our $ur   : shared = 0;
	my $x =0;

	while($q->pending() && $x <  $conf{'max_threads'}){
		$x++;
		threads->new(\&GetResponse);
	}

	@threads = threads->list();
        foreach my $running (@threads) {
		$running->join();
		print "[*] Remaining tests: ". $q->pending ." Threads: " . (scalar(threads->list())+1) ."       \r";
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
		print "[*] Remaining tests: ". $q->pending ." Threads: " . (scalar(threads->list())+1) ."       \r";
		if($url1 =~/^https:\/\//){
			my $http = Uniscan::Http->new();
			my $response = $http->GETS($url1);
			if($response){
				if($response =~ $conf{'code'} && $pattern !~ m/$response->content/){
					push(@list, $url1);
					if(length($url1) < 99){
						&write('', "| [+] CODE: " .$response." URL: $url1" . " "x(99 - length($url1)));
					}
					else {
						&write('', "| [+] CODE: " .$response." URL: $url1");
					}
				}
			}
			$http = 0;
			$response = 0;
			
		}

		else{
			my $req=HTTP::Request->new(GET=>$url1);
			my $ua=LWP::UserAgent->new(agent => "Uniscan ".$conf{'version'}." http://www.uniscan.com.br/");
			$ua->timeout($conf{'timeout'});
			$ua->max_size($conf{'max_size'});
			$ua->max_redirect(0);
			$ua->protocols_allowed( [ 'http'] );
			if($conf{'proxy'} ne "0.0.0.0" && $conf{'proxy_port'} != 65000){
				$ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
			}

			my $response=$ua->request($req);
			if($response){
				if($response->code =~ $conf{'code'} && $pattern !~ m/$response->content/){
					push(@list, $url1);
					if(length($url1) < 99){
						&write('', "| [+] CODE: " .$response->code."\t URL: $url1" . " "x(99 - length($url1)));
					}
					else {
						&write('', "| [+] CODE: " .$response->code."\t URL: $url1");
					}
				}
			}
			$req = 0;
			$ua = 0;
			$response = 0;
		}
	}
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

	open(my $log, ">>". $conf{'log_file'}) or die "$!\n";
	print $log "$text\n";
	close($log);

	if(length($text) < 82){
		$text .= " "x(82 - length($text));
	}

	print "$text\n";

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
	$url .= "uniscan". rand(10000) ."uniscan/";
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
            		$ss {$s} = 1;
        	}
    	}
    	return (@novo);
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
	print 	"OPTIONS:\n".
		"\t-h \thelp\n".
		"\t-u \t<url> example: https://www.example.com/\n".
		"\t-f \t<file> list of url's\n".
		"\t-b \tUniscan go to background\n".
		"\t-q \tEnable Directory checks\n".
		"\t-w \tEnable File checks\n".
		"\t-e \tEnable robots.txt check\n".
		"\t-d \tEnable Dynamic checks\n".
		"\t-s \tEnable Static checks\n".
		"\t-r \tEnable Stress checks\n".
		"\t-i \t<dork> Bing search\n".
		"\t-o \t<dork> Google search\n".
		"\n".
		"usage: \n".
		"[1] perl $0 -u http://www.example.com/ -qweds\n".
		"[2] perl $0 -f sites.txt -bqweds\n".
		"[3] perl $0 -i uniscan\n".
		"[4] perl $0 -i \"ip:xxx.xxx.xxx.xxx\"\n".
		"[5] perl $0 -o \"inurl:uniscan\"\n".
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
	&write("a", "###############################\n# Uniscan project             #\n# http://www.uniscan.com.br/  #\n###############################\nV. ". $conf{'version'} ."\n\n");
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
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	$year += 1900;
	$mon++;
	return "$mday-$mon-$year $hour:$min:$sec";
}


sub CheckUpdate(){
	my $self = shift;
	my $h = Uniscan::Http->new();
	my $response = $h->GET("http://www.uniscan.com.br/version.txt");
	chomp $response;
	if($response != $conf{'version'}){
		&write("self", "New version $response is avaliable");
		&write("self", "More details in http://www.uniscan.com.br/\n\n");
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





1;


