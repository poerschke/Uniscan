package Uniscan::Google;

use Moose;
use Uniscan::Functions;
use Uniscan::Http;


sub search(){
	my ($self, $search) = @_;

	my $func = Uniscan::Functions->new();
	my $http = Uniscan::Http->new();
      
	my $n = 0;
	my $google = "";
	my %sites = ();
	$func->write("| [+] Google search for: $search");
	for($n=0; $n<700; $n+=10){
		$google = 'http://www.google.com/search?q='. $search .'&num=100&hl=pt-BR&safe=off&ie=UTF-8&start='. $n .'&sa=N';
		my $response = $http->GET($google);
		while ($response =~  m/<a href=\"https?:\/\/([^>\"]+)\" class=l>/g){
			if ($1 !~ m/google|cache|translate/){
				my $site = $1;
				$site = substr($site, 0, index($site, '/')) if($site =~/\//);
				if(!$sites{$site}){
					$sites{$site} = 1;
				}
			}
		}
	}

	my $i =0;
	open(my $file, ">>sites.txt");
	foreach my $key (keys %sites){
		print $file "http://" . $key . "/\n";
		$i++;
	}
	close($file);
	$func->write("| [+] Google returns $i sites.");
	$func->write("| [+] Google search finished.");

}




1; 