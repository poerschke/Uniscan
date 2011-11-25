package Uniscan::Http;

use Moose;
use Net::SSLeay qw(get_https post_https sslcat make_headers make_form get_https3);
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use Uniscan::Configure;
use HTTP::Cookies;




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
	my $req=HTTP::Request->new(HEAD=>$url1);
	$req->authorization_basic($conf{'basic_login'}, $conf{'basic_pass'}) if($conf{'use_basic_auth'} == 1);
        my $ua=LWP::UserAgent->new(agent => $conf{'user_agent'});
        $ua->timeout($conf{'timeout'});
        $ua->max_size($conf{'max_size'});
	$ua->protocols_allowed( [ 'http'] );
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
	return if(!$url1);

        if($url1 =~/^https/){
                if($conf{'use_proxy'} == 1){
                        Net::SSLeay::set_proxy($conf{'proxy'}, $conf{'proxy_port'});
                }
                substr($url1,0,8) = "";
                my $pos = index($url1, '/');
                my $url2 = substr($url1, 0, $pos);
                my $file = substr($url1, $pos, length($url1));
		my $page = 0;
                ($page) = get_https($url2, 443, $file) if($conf{'use_basic_auth'} != 1);
		($page) = get_https($url2, 443, $file, make_headers('Authorization' =>'Basic ' . MIME::Base64::encode("$conf{'basic_login'}:$conf{'basic_pass'}",'')), '') if($conf{'use_basic_auth'} == 1);
                return $page;
	}

        else{
        my $req = HTTP::Request->new(GET=>$url1);
	$req->authorization_basic($conf{'basic_login'}, $conf{'basic_pass'}) if($conf{'use_basic_auth'} == 1);
        my $ua	= LWP::UserAgent->new(agent => $conf{'user_agent'});

	$ua->cookie_jar($cookie_jar);
        $ua->timeout($conf{'timeout'});
        $ua->max_size($conf{'max_size'});
	$ua->protocols_allowed( [ 'http'] );
        if($conf{'use_proxy'} == 1){
                $ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
        }

        my $response=$ua->request($req);
	if($response->code == 404){
		return "page 404 ";
	}

        return $response->content;
        }
}


##############################################
#  Function GETS
#  this function return de response of 
#  a HTTPS GET request
#
#  Param: $url
#  Return: $response
##############################################

sub GETS(){
        my ($self, $url1 )= @_;
	return if(!$url1);

	if($conf{'use_proxy'} == 1){
		Net::SSLeay::set_proxy($conf{'proxy'}, $conf{'proxy_port'});
        }

        substr($url1,0,8) = "";
        my $pos = index($url1, '/');
        my $url2 = substr($url1, 0, $pos);
        my $file = substr($url1, $pos, length($url1));
        my ($page, $response, $headers, $server_cert)= get_https3($url2, 443, $file);
	return $response;
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
        $data =~ s/\r//g;
        if($url1 =~/^https/){
                if($conf{'use_proxy'} == 1){
                        Net::SSLeay::set_proxy($conf{'proxy'}, $conf{'proxy_port'});
                }
                substr($url1,0,8) = "";
                my $pos = index($url1, '/');
                my $url2 = substr($url1, 0, $pos);
                my $file = substr($url1, $pos, length($url1));
		my ($page, $response, %reply_headers) = 0;
                ($page, $response, %reply_headers) = post_https($url2, 443, $file, '', $data) if($conf{'use_basic_auth'} != 1);
		($page, $response, %reply_headers) = post_https($url2, 443, $file, make_headers('Authorization' =>'Basic ' . MIME::Base64::encode("$conf{'basic_login'}:$conf{'basic_pass'}",'')), $data) if($conf{'use_basic_auth'} == 1);

                return $page;
        }

        else{
        my $headers = HTTP::Headers->new();
        my $request= HTTP::Request->new("POST", $url1, $headers);
	$request->authorization_basic($conf{'basic_login'}, $conf{'basic_pass'}) if($conf{'use_basic_auth'} == 1);
        $request->content($data);
        $request->content_type('application/x-www-form-urlencoded');
        my $ua=LWP::UserAgent->new(agent => $conf{'user_agent'});
	
	$ua->cookie_jar($cookie_jar);

        $ua->timeout($conf{'timeout'});
        $ua->max_size($conf{'max_size'});
	$ua->protocols_allowed( [ 'http'] );
        if($conf{'use_proxy'} == 1){
                $ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
        }
        my $response=$ua->request($request);
        return $response->content;
        }
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
        my $headers = HTTP::Headers->new();
        my $req=HTTP::Request->new(PUT=>$url, $headers, $data);
	$req->authorization_basic($conf{'basic_login'}, $conf{'basic_pass'}) if($conf{'use_basic_auth'} == 1);
        my $ua=LWP::UserAgent->new(agent => $conf{'user_agent'});
        $ua->timeout($conf{'timeout'});
        $ua->max_size($conf{'max_size'});
	$ua->protocols_allowed( [ 'http'] );
        if($conf{'use_proxy'} == 1){
                $ua->proxy(['http'], 'http://'. $conf{'proxy'} . ':' . $conf{'proxy_port'} . '/');
        }

        my $response=$ua->request($req);
        return $response->content;
}


 
1;
