    package Uniscan::Factory;
    
    sub create {
	my $class          = shift;
	my $requested_type = shift;
	    my $plugin_type	   = shift;
	    my $class          = "Plugins::". $plugin_type."::".$requested_type;
	    $plugin_type =~ s/::/\//g if($plugin_type =~/::/);
	my $location       = "Plugins/$plugin_type/$requested_type.pm";
	
	require $location;
    
	return $class->new(@_);
    }
    
    1;
