package Uniscan::Bing;

use Moose;
use Uniscan::Http;
use Uniscan::Functions;


sub search(){
	my ($self, $search) = @_;

	my $func = Uniscan::Functions->new();
	my $http = Uniscan::Http->new();
	my $x = 0;
	my $y = 701;
	my ($bing, $response) = "";
	my %sites = ();
	$func->write("| [+] Bing search for: $search");
	for($x=0; $x <= $y; $x+=10){
		$bing = 'http://www.bing.com/search?q='.$search.'&first='.$x.'&FORM=PORE';
		$response = $http->GET($bing);
		while ($response =~  m/<cite>(.*?)<\/cite>/g){
			my $site = $1;
			$site =~s/<strong>|<\/strong>//g;
			$site = substr($site, 0, index($site, '/')) if($site =~/\//);
			if(!$sites{$site}){
				$sites{$site} = 1;
			}
		}
		$y = 10 * &getmax($response) + 1;
	}
	my $i =0;

	open(my $file, ">>sites.txt");
	foreach my $key (keys %sites){
		$i++;
		print $file "http://$key/\n";
	}
	close($file);
	$func->write("| [+] Bing returns $i sites.");
	$func->write("| [+] Bing search finished.");
}


sub getmax(){
	my $content = shift;
	my $max = 0;
	while($content =~m/<li><a href="\/search\?q=.+">(\d+)<\/a><\/li>/g){
		$max = $1;
	}
	return $max;
}
1;