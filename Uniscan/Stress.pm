package Uniscan::Stress;

use Moose;
use Uniscan::Factory;
use Uniscan::Functions;

our @plugins = ();


sub loadPlugins(){
	my $self = shift;
	@plugins = ();
	my $func = Uniscan::Functions->new();
	opendir(my $dh, "./Plugins/Stress/") || die "$!\n";
	my @plug = sort grep {/\.pm$/} readdir($dh);
	closedir $dh;
	my $x=0;
	foreach my $d (@plug){
		$d =~ s/\.pm//g;
		push(@plugins, Uniscan::Factory->create($d, "Stress"));
		$func->write("| Plugin name: $plugins[$x]->{name} v.$plugins[$x]->{version} Loaded.") if($plugins[$x]->status() == 1);
		$x++;
	}
}

	
sub run(){
	my ($self, $url) = @_;
	# plugins start
	foreach my $p (@plugins){
		$p->execute($url) if($p->status() == 1);
	}
	# plugins end
}

1;
