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
	use Thread::Semaphore;
	use URI;
	
	#testadas
	our %ignored  	: shared = ( );
	my %files = ( );
	our @list	: shared = ( );
	my $q = new Thread::Queue;
	our %forms	: shared = ( );
	our %urls	: shared = ( );
	my $p = 0;
	my $u		: shared = 0;
	my $reqs	: shared = 0;
	our $url;
	our @url_list = ( );
	our $func = Uniscan::Functions->new();
	our %conf = ( );
	our $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
	%conf = $cfg->loadconf();
	my $pat = 0;
	our @plugins = ();
	my $semaphore = Thread::Semaphore->new();
	#nao testadas

	
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
	
		while ($content =~  m/<select(.+?)>/gi){
			my $inp = $1;
			if($inp =~ /name/i){
				$inp =~ m/name *= *"(.+?)"/gi;
				push(@input, $1);
			}
		}
	
		while ($content =~  m/<textarea(.+?)>/gi){
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
		while($content =~ m/<form(.+?)<\/form>/gi){
			my $cont = $1;
			if($cont =~/method/i && $cont =~/action/i)
			{
				$cont =~ m/action=["'](.+?)["']/gi;
				my $action = $1;
				$action = $site if(!$action);
				return if($action =~ /"|'|>|</);
				if($action =~ /^\//){
					$action = $func->get_url($site) . $action;
				}
				elsif($action =~ /^https?:\/\//){
					return if($action !~ $func->get_url($site));
				}
				else{
					my $x = 0;
					while($action =~ m/^\.\.\//g){
						$x++;
					}
					my $i;
					$url2 = substr($site, 0, rindex($site, '/')+1);
					for($i=0;$i<$x;$i++){
						$action = substr($action, 3, length($action));
						$url2 = substr($url2, 0, rindex($url2, '/'));
						$url2 = substr($url2, 0, rindex($url2, '/')+1);
					}
					my $ho = &host($site);
					next if($url2 !~/^https?:\/\/$ho\//);
					$action = $url2 . $action;
				}
				$cont =~ m/method *= *["'](.+?)["']/gi;
				my $method = $1;
				$method = "post" if(!$method);
	
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
							$semaphore->down();
							push(@list, $url2) if($url2 !~/\s|"|'|:/);
							$semaphore->up();
							
						}
					}
					else{
						$semaphore->down();
						$ignored{$url2} = 1;
						$semaphore->up();
					}
				}
				else {
					my $data;
					foreach my $var (@inputs){
						$data .='&'.$var.'=123' if($var);
					}
					if(!$forms{$action}){
						if($data){
							$semaphore->down();
							$forms{$action} = 0;
							$forms{$action} = $data;
							$semaphore->up();
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
		if($base !~ /\/\/$/ && $base =~/https?:\/\//){
			my @lst = ();
			my @ERs = (	'href\s*=\s*"(.+?)"',
					'href\s*=\s*\'(.+?)\'',
					"location.href='(.+?)'",
					"window\.open\('(.+?)'(,'')*\)",
					'src\s*=\s*["\'](.+?)["\']',
					'location.href\s*=\s*"(.+?)"', 
					'<meta.+content=\"\d+;\s*URL=(.+?)\".*\/?>',
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
			return $url."a" if(!$result);
			return if($result =~/\Q$pat\E/);
			if($result){
			my @lines = split('\n', $result);
			# plugins start
				foreach my $p (@plugins){
					$p->execute($base, $result) if($p->status() == 1);
				}
			# plugins end
	
				if($result =~ m/<form/gi){
					&add_form($base, $result);
				}
	
				chomp($result);
				foreach my $line (@lines){
				foreach my $er (@ERs){
					while ($line =~ m/$er/gi){
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
								my $uurl = $base;
								if($uurl =~ /^http:\/\//){
									$uurl =~s/http:\/\///g;
									$uurl = substr($uurl, 0, index($uurl, '?')) if($uurl =~/\?/);
									$uurl = substr($uurl, 0, rindex($uurl, '/')+1);
									if($link =~/^\.\.\//){
										while($link =~ /^\.\.\//){
											$link = substr($link, 3, length($link));
											$uurl = substr($uurl, 0, rindex($uurl, '/'));
											$uurl = substr($uurl, 0, rindex($uurl, '/')+1);
										}
										$link = "http://" . $uurl . $link;
									}
									else{
										$uurl = substr($uurl, 0, rindex($uurl, '/'));
										$link = "http://" . $uurl . '/' . $link;
									}
								}
								else{
									$uurl =~s/https:\/\///g;
									if($link =~/^\.\.\//){
										while($link =~ /^\.\.\//){
											$link = substr($link, 3, length($link));
											$uurl = substr($uurl, 0, rindex($uurl, '/'));
											$uurl = substr($uurl, 0, rindex($uurl, '/')+1);
										}
										$link = "https://" . $uurl . $link;
									 }
									else{
										$uurl = substr($uurl, 0, rindex($uurl, '/'));
										$link = "https://" . $uurl . '/' . $link;
									}
								}
							}
						
						}
						chomp $link;
						
						$link =~s/&amp;/&/g;
						$link =~ s/\.\///g; 
						$link =~ s/ //g;
						my $url_temp = &host($url);
						if($link =~/^https?:\/\// && $link =~/^$url/ && $link !~/#|javascript:|mailto:|\{|\}|function\(|;/i){
							my $fil = $func->get_file($link);
							my $ext = &get_extension($fil);	
							if($conf{'extensions'} !~/\Q$ext\E/i){
								$files{$fil}++;
								if($files{$fil} <= $conf{'variation'} && rindex($link, $url_temp) < length($url)){
									push (@lst,$link);
								}
							}
							else {
								$semaphore->down();
								$ignored{$link} = 1;
								$semaphore->up();
							}
							my $l = $link;
							my $proto = 0;
							if($l =~/^http:\/\//){
								$proto = 7;
							}
							else{
								$proto = 8;
							}
							$l =~ s/https?:\/\///g;
							my $pb = index($l, '/') + $proto+1;
							my $ub = 2000;
							while($ub > $pb){
								$ub = rindex($link, '/');
								$link = substr($link, 0, $ub);
								if(!$files{$link}  && rindex($link, $url_temp) < length($url)){
									push(@lst, $link."/");
									$files{$link."/"} = 1;
								}
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
		
		while($q->pending() > 0 && $reqs <= $conf{'max_reqs'}){
			my $l = $q->dequeue;
			next if(not defined $l);
			$semaphore->down();
			$reqs++;
			$semaphore->up();
			my @tmp = &get_urls($l);
			foreach my $t (@tmp){
				if(!$urls{$t}){
					$semaphore->down();
					push(@list, $t);
					$semaphore->up();
					$q->enqueue($t);
					$u++;
					$semaphore->down();
					$urls{$t} = 1;
					$semaphore->up();
					#$func->write("| ".$t);
				}
			}
			$semaphore->down();
			printf("\r| [*] ". $conf{'lang28'} .": [%d - %d]\r", $reqs, $u);
			$semaphore->up();
		}
		$q->enqueue(undef);
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
		$reqs = 0;
		$pat = $func->INotPage($url_list[1]);
		foreach my $ur (@url_list){
			$q->enqueue($ur);
		}
		$semaphore->down();
		$u = scalar(@url_list);
		$semaphore->up();
		$url = $url_list[0];
	
		my $x =0;
		my @threads = ();
		while($q->pending() > 0 && $x < $conf{'max_threads'}){
			$x++;
			push @threads, threads->new(\&crawling);
			sleep($conf{'timeout'}) if($q->pending() == 0 && $x <$conf{'max_threads'});       
		}
		sleep(2);
		foreach my $running (@threads) {
			$running->join();
		}
	
		while($q->pending()){
			$q->dequeue;
		}
	
		if($reqs >= $conf{'max_reqs'}){
			$func->write("| [+] ". $conf{'lang29'} .": " . $conf{'max_reqs'} . "             ");
			$func->writeHTMLItem($conf{'lang29'} .": ");
			$func->writeHTMLValue($conf{'max_reqs'});
		}
	
		
	# crawler end
		
		$func->write("| [+] ". $conf{'lang30'} .", ". scalar(@list) ." URL's ". $conf{'lang31'} ."!");
		$func->writeHTMLItem($conf{'lang30'} .", ". $conf{'lang31'} .": ");
		$func->writeHTMLValue(scalar(@list) . " URL's");
	# show plugins results
		foreach my $plug (@plugins){
			$plug->showResults()  if($plug->status() == 1);
			$plug->clean()  if($plug->status() == 1);
		}
		if($conf{'show_ignored'} == 1){
			$func->write("|\n| ". $conf{'lang32'} .": ");
			$func->writeHTMLItem($conf{'lang32'} .": <br>");
			foreach my $key (keys %ignored){
				if($key =~/[jpg|gif|bmp|jpeg|png|swf|js]$/i && $conf{'show_images'} == 1){
					$func->write("| $key");
					$func->writeHTMLValue("$key");
				}
				elsif($key !~/[jpg|gif|bmp|jpeg|png|swf|js]$/i){
					$func->write("| $key");
					$func->writeHTMLValue("$key");
				}
			}
		}
		if($list[0]){
			while($list[0] !~ /^https?:\/\// && $list[0]){
				shift @list;
			}
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
				$func->write("| [+] ".$f);
				$func->writeHTMLValue($f);	
				my ($tag, $dir) = split(' ', $f);
				if($dir){  
				push(@found, $url.$dir) if($dir =~/^\//);
				}
			}
		}
	return @found;
	}
	
	
	sub CheckSitemap(){
		my ($self, $url) = @_;
		my $h = Uniscan::Http->new();
		my @found = ();
		my $content = $h->GET($url."sitemap.xml");
		$content =~s/\n//g;
		$content =~s/\r//g;
		while($content =~ m/<loc>(.+?)<\/loc>/gi){
			my $file = $1;
			if($file =~ /^https?:\/\//){
				my $ho = &host($url);
				if($file =~ /$ho/i){
					$func->write("| [+] ".$file);
					$func->writeHTMLValue($file);
					push @found, $file;
				}
			}
			else{
				$file = $url . $file;
				$func->write("| [+] ".$file);
				$func->writeHTMLValue($file);
				push @found, $file;
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
		$p = 0;
		$u = 0;
		$url = "";
		@url_list = ( );
		%ignored = ( );
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
			$func->write("| ". $conf{'lang33'} .": $plugins[$x]->{name} v.$plugins[$x]->{version} ". $conf{'lang34'} .".") if($plugins[$x]->status() == 1);
			$x++;
		}
		
	
	}
	
	sub host(){
		my $h = shift;
		my $url1 = URI->new( $h || return -1 );
		return $url1->host();
	}
	1;
