package Plugins::Crawler::externalHost;

use Uniscan::Functions;

	my $func = Uniscan::Functions->new();

sub new {
    my $class    = shift;
    my $self     = {name => "External Host Detect", version => 1.1};
	our %external : shared = ();
	our $enabled = 1;
    return bless $self, $class;
}

sub execute {
    my $self = shift;
	my $url = shift;
	my $content = shift;
	$url = $func->get_url($url);
	my @ERs = (	"href=\"(.+)\"", 
				"href='(.+)'", 
				"href=(.+?)>", 
				"location.href='(.+)'",
				"src='(.+)'",
				"src=\"(.+)\"",
				"location.href=\"(.+)\"", 
				"<meta.*content=\"?.*;URL=(.+)\"?.*?>"
			);
			
	foreach my $er (@ERs){
		while ($content =~  m/$er/gi){
			my $link = $1;
			next if($link =~/[\s"']/);
			$link = &get_url($link);
			if($url ne $link){
				$external{$link}++ if($link);
			}
		}
	}
	

}


sub showResults(){
	my $self = shift;
	$func->write("|\n| External hosts:");
	foreach my $url (%external){
		$func->write("| [+] External Host Found: ". $url . " " . $external{$url} . "x times") if($external{$url});
	}
}

sub getResults(){
	my $self = shift;
	return %external;
}

sub clean(){
	my $self = shift;
	%external = ();
}

sub status(){
	my $self = shift;
	return $enabled;
}

sub get_url(){
	my $url = shift;
	if($url =~/http:\/\//){
		$url =~s/http:\/\///g;
		$url = substr($url, 0, index($url, '/')) if($url =~/\//);
		return "http://" . $url;
	}
	if($url =~/https:\/\//){
		$url =~s/https:\/\///g;
		$url =  substr($url, 0, index($url, '/')) if($url =~/\//);
		return "https://" . $url;
	}
}



1;
