package Plugins::Crawler::FCKeditor;

use IO::Socket::INET;
use Uniscan::Functions;
use URI;
use Thread::Semaphore;
use Uniscan::Configure;
	
my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();
my $func = Uniscan::Functions->new();
our %upload : shared = ();
my $semaphore = Thread::Semaphore->new();

sub new {
	my $class = shift;
	my $self = {name => "FCKeditor upload test", version => 1.0 };
	our $enabled = 1; # 1 = enabled and 0 = disabled
	return bless $self, $class;
}

sub execute {

my $self = shift;
my $url = shift;
my $content = shift;
my @connectors = (	"/php/upload.php",
					"/asp/upload.asp",
					"/aspx/upload.aspx",
					"/cfm/upload.cfm",
					"/perl/upload.cgi",
					"/py/upload.py");
					
if($content =~/<title>FCKeditor|FCKeditor - The text editor for internet/i && $content =~ /id="frmUpload"/){
	my $host = &host($url);
	my $temp = $url;
	$temp =~ s/https?:\/\///g;
	$temp =~ s/$host//g;
	my $path = $temp;
	foreach my $con (@connectors){
		my $u = substr($path, 0, rindex($path, '/'));
		$u .= $con;
	    my $sock = IO::Socket::INET->new (PeerAddr => $host,PeerPort => 80, Proto    => 'tcp') || return;
        print $sock "POST /".$u." HTTP/1.1\r\n" ;
        print $sock "Host: ".$host."\r\n" ;
        print $sock "User-Agent:Mozilla/5.0 (X11; U; Linux i686; pt-BR; rv:1.9.2.24) Gecko/20111107 Ubuntu/10.10 (maverick) Firefox/3.6.24\r\n" ;
        print $sock 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'."\r\n" ;
        print $sock 'Accept-Language: pt-br,pt;q=0.8,en-us;q=0.5,en;q=0.3'."\r\n" ;
        print $sock 'Accept-Encoding: gzip,deflate'."\r\n" ;
        print $sock 'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7'."\r\n" ;
        print $sock 'Keep-Alive: 115'."\r\n" ;
        print $sock 'Connection: keep-alive'."\r\n" ;
        print $sock 'Referer: http://'. $host .'/FCKeditor/editor/filemanager/upload/test.html'."\r\n" ;
        print $sock 'Content-Type: multipart/form-data; boundary=---------------------------3404088951808214906347034904'."\r\n" ;
        print $sock 'Content-Length: 236'."\r\n\r\n" ;
        print $sock '-----------------------------3404088951808214906347034904'."\r\n" ;
        print $sock 'Content-Disposition: form-data; name="NewFile"; filename="uniscan.txt"'."\r\n" ;
        print $sock 'Content-Type: text/plain'."\r\n" ;
        print $sock "\r\n" ;
        print $sock 'teste uniscan'."\n" ;
        print $sock "\r\n" ;
        print $sock '-----------------------------3404088951808214906347034904--'."\r\n" ;
		my $result;
		while(<$sock>){
			$result .= $_;
		}
		$result =~/OnUploadCompleted\((\d+)\,"(.*)"\,"(.*)"\, ""\)/;
		my $code = $1;
		my $path_file = $2;
		my $file_name = $3;
		if($code == 201 && $path_file =~/uniscan/ && $file_name=~/uniscan/){
				$semaphore->down();
				$upload{ "http://" . $host . $u} = $path_file;
				$semaphore->up();
		}
		
	}
}


}

# crawler will call this method after crawled target
sub showResults(){
    my $self = shift;
    $func->write("|\n| ". $conf{'lang106'} .":");
    $func->writeHTMLItem($conf{'lang106'} .":<br>");
    foreach my $url (keys %upload){
        $func->write("| [+] ". $conf{'lang107'} .": ". $url . " ". $conf{'lang108'} .": " . $upload{$url}) if($upload{$url});
	$func->writeHTMLValue($conf{'lang107'} .": ". $url. " ". $conf{'lang108'} .": " . $upload{$url}) if($upload{$url});
	$func->writeHTMLVul("FCKEDITOR") if($upload{$url});
    }
}

sub clean(){
	my $self = shift;
	%upload = ();
}
# return the status of your plug-in
sub status(){
	my $self = shift;
	return $enabled;
}

sub host(){
  	my $h = shift;
  	my $url1 = URI->new( $h || return -1 );
  	return $url1->host();
}

1;
