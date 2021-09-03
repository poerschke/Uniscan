package Uniscan::Google;

use Moose;
use Uniscan::Functions;
use Uniscan::Http;
use Uniscan::Configure;
	
my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();


sub search(){
	my ($self, $search) = @_;

	my $func = Uniscan::Functions->new();
	my $http = Uniscan::Http->new();
      
	my $n = 0;
	my $google = "";
	my %sites = ();
	$func->write("| [+] ". $conf{'lang97'} .": $search");
	$func->writeHTMLValue($conf{'lang97'} .": $search");
	for($n=0; $n<200; $n+=10){
		$google = 'http://www.google.com.ar/search?hl=es&q='. $search .'&start='. $n .'&sa=N';
		my $response = $http->GET($google);
		while ($response =~  m/<h3 class\=\"r\"><a href\=\"https?:\/\/([^>\"]+)\" class\=/g){
			if ($1 !~ m/google|cache|translate/){
				my $site = $1;
				$site = substr($site, 0, index($site, '/')) if($site =~/\//);
				$site = "http://" . $site . "/";
				if(!$sites{$site}){
					$sites{$site} = 1;
				}
			}
		}
	}



	my $i =0;
	open(my $file, ">>", "sites.txt");
	foreach my $key (keys %sites){
		#print $file "http://" . $key . "/\n";
                print $file $key. "\n";
		$i++;
	}
	close($file);
	$func->write("| [+] Google ". $conf{'lang25'} ." $i sites.");
	$func->writeHTMLValue("Google ". $conf{'lang25'} ." $i sites.");
	$func->write("| [+] ". $conf{'lang98'} .".");
	$func->writeHTMLValue($conf{'lang98'} .".");

}




1; 
