	package Uniscan::Bing;
	
	use Moose;
	use Uniscan::Http;
	use Uniscan::Functions;
	use Uniscan::Configure;
	
	my %conf = ( );
	my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
	%conf = $cfg->loadconf();
	
	
	sub search(){
		my ($self, $search) = @_;
	
		my $func = Uniscan::Functions->new();
		my $http = Uniscan::Http->new();
		my $x = 0;
		my $y = 701;
		my ($bing, $response) = "";
		my %sites = ();
		$func->write("| [+] ". $conf{'lang27'} .": $search");
		$func->writeHTMLValue($conf{'lang27'} .": $search");
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
	
		open(my $file, ">>", "sites.txt");
		foreach my $key (keys %sites){
			$i++;
			print $file "http://$key/\n";
		}
		close($file);
		$func->write("| [+] Bing ". $conf{'lang25'} ." $i sites.");
		$func->writeHTMLValue("Bing" . $conf{'lang25'} ." $i sites.");
		$func->write("| [+] ". $conf{'lang26'} .".");
		$func->writeHTMLValue( $conf{'lang26'} .".");
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