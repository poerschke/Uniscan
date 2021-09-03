package Uniscan::Scan;

use Moose;
use Uniscan::Factory;
use Uniscan::Functions;
use Uniscan::Configure;
	
my %conf = ( );
my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();
our @pluginsD = ();
our @pluginsS = ();
our $func = Uniscan::Functions->new();

sub loadPluginsDynamic(){
	my $self = shift;
	
	if(!scalar(@pluginsD)){
		opendir(my $dh, "./Plugins/Tests/Dynamic/") || die "$!\n";
		my @plug = sort grep {/\.pm$/} readdir($dh);
		closedir $dh;
		my $x=0;
		foreach my $d (@plug){
			$d =~ s/\.pm//g;
			push(@pluginsD, Uniscan::Factory->create($d, "Tests::Dynamic"));
			$func->write("| ". $conf{'lang33'}. ": $pluginsD[$x]->{name} v.$pluginsD[$x]->{version} ". $conf{'lang34'} .".") if($pluginsD[$x]->status() == 1);
			$x++;
		}
	}
}

	
sub runDynamic(){
	my ($self, @urls) = @_;
	# plugins start
	foreach my $p (@pluginsD){
		$p->execute(@urls) if($p->status() == 1);
		$p->clean()  if($p->status() == 1);
	}
	
	# plugins end
}

	
sub loadPluginsStatic(){
	my $self = shift;

	if(!scalar(@pluginsS)){
		opendir(my $dh, "./Plugins/Tests/Static/") || die "$!\n";
		my @plug = sort grep {/\.pm$/} readdir($dh);
		closedir $dh;
		my $x =0;
		foreach my $d (@plug){
			$d =~ s/\.pm//g;
			push(@pluginsS, Uniscan::Factory->create($d, "Tests::Static"));
			$func->write("| ". $conf{'lang33'} .": $pluginsS[$x]->{name} v.$pluginsS[$x]->{version} ". $conf{'lang34'} .".") if($pluginsS[$x]->status() == 1);
			$x++;
		}
		
	}
}
	

sub runStatic(){
	my ($self, $url) = @_;
	# plugins start
	foreach my $p (@pluginsS){
		$p->execute($url) if($p->status() == 1);
		$p->clean()  if($p->status() == 1);
	}
	# plugins end
}

1;
