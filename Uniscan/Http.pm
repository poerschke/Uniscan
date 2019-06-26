package Uniscan::Http;

use Moose;
#use Net::SSLeay qw(get_https post_https sslcat make_headers make_form get_https3);
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use Uniscan::Configure;
use HTTP::Cookies;
use LWP::Protocol::https;





our %conf = ( );
our $c = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $c->loadconf();

our $cookie_jar = HTTP::Cookies->new(file => "cookies.lwp",autosave => 1);
##############################################
#  Function HEAD
#  this function return the response code of
#  a HEAD request
#
#  Param: $url
#  Return: $response
##############################################

sub HEAD(){
	my ($self, $url1) = @_;
	&writereq("HEAD", $url1);
	my $req=HTTP::Request->new(HEAD=>$url1);
	$req->authorization_basic($conf{'basic_login'}, $conf{'basic_pass'}) if($conf{'use_basic_auth'} == 1);
	my $ua=LWP::UserAgent->new(agent => $conf{'user_agent'});
	$ua->timeout($conf{'timeout'});
	$ua->max_size($conf{'max_size'});
	$ua->protocols_allowed( [ 'http', 'https'] );
	if($conf{'use_proxy'} == 1){
		$ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
	}
	my $response=$ua->request($req);
	return $response;

}



##############################################
#  Function GET
#  this function return de response content of 
#  a GET request
#
#  Param: $url
#  Return: $content
##############################################


sub GET(){
        my ($self, $url1 )= @_;
	return 0 if(!$url1);
	return 0 if($url1 !~/^https?:\/\//);
	&writereq("GET", $url1);

        my $req = HTTP::Request->new(GET=>$url1);
	$req->authorization_basic($conf{'basic_login'}, $conf{'basic_pass'}) if($conf{'use_basic_auth'} == 1);
        my $ua	= LWP::UserAgent->new(agent => $conf{'user_agent'});

	$ua->cookie_jar($cookie_jar);
        $ua->timeout($conf{'timeout'});
        $ua->max_size($conf{'max_size'});
	$ua->protocols_allowed( [ 'http', 'https'] );
        if($conf{'use_proxy'} == 1){
                $ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
        }

        my $response=$ua->request($req);
	if($response->is_success){
	        return $response->decoded_content;
	}
	else{
		return "";
	}

}


##############################################
#  Function post_http
#  this function do a POST request on target
#
#  Param: $url to POST, $data to post
#  Return: $request content 
##############################################

sub POST(){
        my ($self, $url1, $data) = @_;
	return if(!$url1);
	return 0 if($url1 !~/^https?:\/\//);
	&writereq("POST", $url1);
        $data =~ s/\r//g;


        my $headers = HTTP::Headers->new();
        my $request= HTTP::Request->new("POST", $url1, $headers);
	$request->authorization_basic($conf{'basic_login'}, $conf{'basic_pass'}) if($conf{'use_basic_auth'} == 1);
        $request->content($data);
        $request->content_type('application/x-www-form-urlencoded');
        my $ua=LWP::UserAgent->new(agent => $conf{'user_agent'});
	
	$ua->cookie_jar($cookie_jar);

        $ua->timeout($conf{'timeout'});
        $ua->max_size($conf{'max_size'});
	$ua->protocols_allowed( [ 'http', 'https'] );
        if($conf{'use_proxy'} == 1){
                $ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
        }
        my $response=$ua->request($request);
        return $response->decoded_content;
        }



##############################################
#  Function PUT
#  this function return de response content of 
#  a PUT request
#
#  Param: $url, $data
#  Return: $content
##############################################

sub PUT(){
	my($self, $url, $data) = @_;
	return if(!$url);
	return 0 if($url !~/^https?:\/\//);
	&writereq("PUT", $url);
        my $headers = HTTP::Headers->new();
        my $req=HTTP::Request->new(PUT=>$url, $headers, $data);
	$req->authorization_basic($conf{'basic_login'}, $conf{'basic_pass'}) if($conf{'use_basic_auth'} == 1);
        my $ua=LWP::UserAgent->new(agent => $conf{'user_agent'});
        $ua->timeout($conf{'timeout'});
        $ua->max_size($conf{'max_size'});
	$ua->protocols_allowed( [ 'http', 'https'] );
        if($conf{'use_proxy'} == 1){
                $ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
        }
        my $response=$ua->request($req);
        return $response->content;
}

sub writereq(){
	my ($met, $req) = @_;
	if($conf{'write_reqs'} == 1){
		open(my $f, ">>", "requests.txt");
		print $f "Method: $met URL: $req\n";
		close($f);
	}
}
 
1;
