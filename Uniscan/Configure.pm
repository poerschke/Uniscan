	package Uniscan::Configure;
	
	use Moose;
	
	has 'conffile' => (is => 'rw', isa => 'Str', required =>1);
	
	
	##############################################
	#  Function loadconf
	#  this function load the configuration file
	# 
	#
	#  Param: nothing
	#  Return: %configuration
	##############################################
	
	sub loadconf() {
		my $self = shift;
		my %conf = ( );
		my $C;
		open($C, "<", $self->conffile) or die("ERROR: Could not open ". $self->conffile ." for read: $!\n");
		while(<$C>) {
			my $line = $_;
			chomp $line;
			
			if($line !~/^[\s\n#]|^$/){
				my ($key, $value) = split('=', $line, 2);
				$value =~ s/\s+//g;
				$key =~ s/\s+//g;
				$conf{$key} = $value;
			}
		}
		close($C);
		if(!-e "Languages/" . $conf{'lang'} . ".lang"){
			die("ERROR: Language file Languages/" . $conf{'lang'}  . ".lang not exists\n");
		}
		
		open($C, "<", "Languages/". $conf{'lang'}. ".lang") or die("ERROR: Could not open Languages/". $conf{'lang'} .".lang for read: $!\n");
		while(<$C>) {
			my $line = $_;
			chomp $line;
			
			if($line !~/^[\s\n#]|^$/){
				my ($key, $value) = split('=', $line, 2);
				$key =~ s/\s+//g;
				$conf{$key} = $value;
			}
		}
		close($C);
		return %conf;
	}
	 
	1;
