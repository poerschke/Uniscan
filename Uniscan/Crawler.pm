package Uniscan::Crawler;

use Moose;
use Uniscan::Http;
use threads;
use threads::shared;
use Thread::Queue;
use strict;
use Uniscan::Configure;
use Uniscan::Functions;
use Uniscan::Factory;


our %files	: shared = ( );
our @list	: shared = ( );
our %forms	: shared = ( );
our %urls	: shared = ( );
our $q :shared = new Thread::Queue;
our $p		: shared = 0;
our $u		: shared = 0;
our $reqs	: shared = 0;
our $url;
our @url_list = ( );
our $func = Uniscan::Functions->new();
our %conf = ( );
our $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
%conf = $cfg->loadconf();
our $pat :shared = 0;
our @plugins = ();

##############################################
#  Function get_input
#  this function identifies the inputs on the 
#  content of a page and stores it in an array
#
#  Param: $content of an page
#  Return: @array with all inputs found
##############################################




sub get_input(){
	my $content = shift;
	my @input = ();
	while ($content =~  m/<input(.+?)>/gi){
		my $inp = $1;
		if($inp =~ /name/i){
			$inp =~ m/name *= *"(.+?)"/gi;
			push(@input, $1);
		}
	}
	return @input;
}





##############################################
#  Function get_extension
#  this function return the extension of a file
#
#  Param: $path/to/file
#  Return: $extension of file
##############################################

sub get_extension(){
	my  $file = shift;
	if($file =~/\./){
		my $ext = substr($file, rindex($file, '.'), length($file));
		$ext =~ s/ //g;
		if($ext !~/\(|\)|\-|\//){
			return $ext;
		}
		else {
			return 0;
		}
	}
	else{
		return 0;
	}
}



##############################################
#  Function add_form
#  when the crawler identifies a form, this 
#  function is called to add the form and the 
#  inputs in a hash to be tested after
#
#  Param: $url, $content of this url
#  Return: nothing
##############################################


sub add_form(){
	my ($site, $content) = @_;
	my @form = ();
	my $url2;
    
	$content =~ s/\n|\s//g;
   	while($content =~ m/<form(.+?)<\/form/gi){
		my $cont = $1;
		
		if($cont =~/method/i && $cont =~/action/i)
		{
			$cont =~ m/action *= *["'](.+?)["']/gi;
			my $action = $1;
			return if(!$action);
			if($action =~ /^\//){
				$action = $func->get_url($site) . $action;
			}
			elsif($action =~ /^https?:\/\//){
				return if($action !~ $func->get_url($site))
			}
			else{
				my $x = 0;
				while($action =~ m/\.\.\//g){
					$x++;
				}
				my $i;
				$url2 = substr($site, 0, rindex($site, '/')+1);
				for($i=0;$i<$x;$i++){
					$action = substr($action, 3, length($action));
					$url2 = substr($url2, 0, rindex($url2, '/'));
					$url2 = substr($url2, 0, rindex($url2, '/')+1);
				}
				$action = $url2 . $action;
			}
			$cont =~ m/method *= *"(.+?)"/gi;
			my $method = $1;
			return if(!$method);

			my @inputs = &get_input($cont);

			if($method =~ /get/i ){
				$url2 = $action . '?';
				foreach my $var (@inputs){
					$url2 .= '&'.$var .'=123' if($var);
				}
		
				my $fil = $func->get_file($url2);
				my $ext = &get_extension($fil);
				if($conf{'extensions'} !~/$ext/i){
					$files{$fil}++;
					if($files{$fil} <= $conf{'variation'}){
						push(@list, $url2) if($url2 !~/\s|"|'|:/);
					}
				}
			}
			else {
				my $data;
				foreach my $var (@inputs){
					$data .='&'.$var.'=123' if($var);
				}
				if(!$forms{$action}){
					if($data){
					    $forms{$action} = 0;
						$forms{$action} = $data;
						$q->enqueue($action."#".$data) if($action !~/\s|"|'|:/);
					}
				}
			}
		}
	}
}





##############################################
#  Function get_urls
#  this function identify links on a page
#
#  Param: $url to search links
#  Return: @array with links found
##############################################


sub get_urls(){
	my $base = shift; 
	if($base !~ /\/\/$/){
		my @lst = ();
		my @ERs = (	"href=\"(.+)\"", 
				"href='(.+)'", 
				"href=(.+?)>", 
				"location.href='(.+)'",
				"window\.open\('(.+?)'(,'')*\)",
				"src='(.+)'",
				"src=\"(.+)\"",
				"location.href=\"(.+)\"", 
				"<meta.*content=\"?.*;URL=(.+)\"?.*?>"
			);
				
		my $h = Uniscan::Http->new();
		my $data;
		my $result;
		if($base =~/#/){
			($base, $data) = split('#', $base);
			$result = $h->POST($base, $data);
		}
		else{
			$result = $h->GET($base);
		}
		return "a" if(!$result);
		return if($result =~/\Q$pat\E/);
		if($result){

		# plugins start
			foreach my $p (@plugins){
				$p->execute($base, $result) if($p->status() == 1);
			}
		# plugins end

			if($result =~ m/<form/gi){
				&add_form($base, $result);
			}

			chomp($result);
			foreach my $er (@ERs){
				while ($result =~  m/$er/gi)
				{
					my $link = $1;
					if ($link =~/"/){
						$link = substr($link,0,index($link, '"'));
					}
					if ($link =~/'/){
						$link = substr($link,0,index($link, "'"));
					}
				
					if($link !~/^https?:\/\// && $link !~/https?:\/\// && $link !~/:/){
						if($link =~/^\//){
							substr($link,0,1) = "";
							$link = $url . $link;
						}
						else{
							my $u = $base;
							if($u =~ /http:\/\//){
								$u =~s/http:\/\///g;
								$u = substr($u, 0, rindex($u, '/')+1);
								if($link =~/^\.\.\//){
									while($link =~ /^\.\.\//){
										$link = substr($link, 3, length($link));
										$u = substr($u, 0, rindex($u, '/'));
										$u = substr($u, 0, rindex($u, '/')+1);
									}
									$link = "http://" . $u . $link;
								}
								else{
									$u = substr($u, 0, rindex($u, '/'));
									$link = "http://" . $u . '/' . $link;
								}
							}
							else{
								$u =~s/https:\/\///g;
								if($link =~/^\.\.\//){
									while($link =~ /^\.\.\//){
										$link = substr($link, 3, length($link));
										$u = substr($u, 0, rindex($u, '/'));
										$u = substr($u, 0, rindex($u, '/')+1);
									}
									$link = "https://" . $u . $link;
								 }
								else{
									$u = substr($u, 0, rindex($u, '/'));
									$link = "https://" . $u . '/' . $link;
								}
							}
						}
					
					}
					chomp $link;
					$link =~s/&amp;/&/g;
					$link =~ s/\.\///g; 
					$link =~ s/ //g;
					if($link =~/^https?:\/\// && $link =~/^$url/ && $link !~/#|javascript:|mailto:|\{|\}|function\(|;/i){
						my $fil = $func->get_file($link);
						my $ext = &get_extension($fil);
						if($conf{extensions} !~/\Q$ext\E/){
							$files{$fil}++;
							if($files{$fil} <= $conf{'variation'}){
								push (@lst,$link);
							}
							
						}
						
					}
				}
			}
		}
		return @lst;
	}
}



##############################################
#  Function crawling
#  Param: $url
#  Return: @array of urls found on this url
##############################################

sub crawling(){
	
	while($q->pending() && $reqs <= $conf{'max_reqs'}){
		$reqs++;
		my $l = $q->dequeue;
		my @tmp = &get_urls($l);

		foreach my $t (@tmp){
			if(!$urls{$t}){
				push(@list, $t);
				$q->enqueue($t);
				$u++;
				$urls{$t} = 1;
			}
		}
		printf("\r| [*] Crawling: [%d - %d]\r", $reqs, $u);
	}
}



##############################################
#  Function start
#  this function start the crawler
#  
#
#  Param: nothing
#  Return: @array
##############################################


sub start(){
	my $self = shift;
	$q = new Thread::Queue;
	$reqs = 0;
	$pat = $func->INotPage($url_list[1]);
	foreach my $ur (@url_list){
		$q->enqueue($ur);
	}
	$u = scalar(@url_list);
	$url = $url_list[0];

	my $x =0 ;
	while($q->pending() && $x < $conf{'max_threads'}){
		$x++;
		threads->new(\&crawling);
		sleep($conf{'timeout'}) if($q->pending() == 0 && $x <$conf{'max_threads'});       
	}


	my @threads = threads->list();
        foreach my $running (@threads) {
		$running->join();
        }

	while($q->pending()){
		$q->dequeue;
	}
	
# crawler end

	$func->write("| [+] Crawling finished, ". scalar(@list) ." URL's found!");
# show plugins results
	foreach my $plug (@plugins){
		$plug->showResults()  if($plug->status() == 1);
		$plug->clean()  if($plug->status() == 1);
	}
	return @list;
}


##############################################
#  Function AddUrl
#  this function add a url on crawler
# 
#
#  Param: $url
#  Return: nothing
##############################################

sub AddUrl(){
my ($self, $ur) = @_;
push(@url_list, $ur) if($ur =~/^https?/);
}


##############################################
#  Function CheckRobots
#  this function check file /robots.txt
# 
#
#  Param: $url
#  Return: @array
##############################################

sub CheckRobots(){
	my ($self, $url) = @_;
	my $h = Uniscan::Http->new();
	my @found = ();
	my $content = $h->GET($url."robots.txt");
	if($content =~/Allow:|Disallow:/){
	    
		my @file = split("\n", $content);
		foreach my $f (@file){
			my ($tag, $dir) = split(' ', $f);
			if($dir){  
			push(@found, $url.$dir) if($dir =~/^\//);
		        $func->write("| [+] ".$dir);
			}
		}
	}
return @found;
}





##############################################
#  Function GetForms
#  this function return the forms found by
#  crawler
#
#  Param: nothing
#  Return: @array
##############################################

sub GetForms(){
	my $self = shift;
	
	my @f = ();
	foreach my $key (keys %forms){	
		push(@f, $key.'#'.$forms{$key});
	}
	return @f;
}


sub Clear(){
	my $self = shift;
	%files = ( );
	@list = ( );
	%forms = ( );
	%urls = ( );
	$q = 0;
	$p = 0;
	$u = 0;
	$url = "";
	@url_list = ( );
}


sub loadPlugins(){
	@plugins = ();
	opendir(my $dh, "./Plugins/Crawler/") || die "$!\n";
	my @plug = grep {/\.pm$/} readdir($dh);
	closedir $dh;
	my $x=0;
	foreach my $d (@plug){
		$d =~ s/\.pm//g;
		push(@plugins, Uniscan::Factory->create($d, "Crawler"));
		$func->write("| Plugin name: $plugins[$x]->{name} v.$plugins[$x]->{version} Loaded.") if($plugins[$x]->status() == 1);
		$x++;
	}
	

}








1;
