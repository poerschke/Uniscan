package Plugins::Crawler::codeDisclosure;

use Uniscan::Functions;

	my $func = Uniscan::Functions->new();

sub new {
    my $class    = shift;
    my $self     = {name => "Code Disclosure", version => 1.0};
	our %source : shared = ();
	our $enabled = 1;
    return bless $self, $class;
}

sub execute {
    my $self = shift;
	my $url = shift;
	my $content = shift;
	my @codes = ('<\?php', '#include <', '#!\/usr', '#!\/bin', 'import java\.', 'public class .+\{', '<\%.+\%>', '<asp:', 'package\s.+\;.*');

	
	foreach my $code (@codes){
		if($content =~ /$code/i){
			$source{$url}++;
		}
	}
}


sub showResults(){
	my $self = shift;
	$func->write("|\n| Source Code:");
	foreach my $url (%source){
		$func->write("| [+] Source Code Found: ". $url . " " . $source{$url} . "x times") if($source{$url});
	}
}

sub getResults(){
	my $self = shift;
	return %source;
}

sub clean(){
	my $self = shift;
	%source = ();
}

sub status(){
	my $self = shift;
	return $enabled;
}

1;
