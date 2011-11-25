#!/usr/bin/env perl

use lib "./Uniscan";
use Uniscan::Crawler;
use Uniscan::Functions;
use Uniscan::Scan;
use Uniscan::Bing;
use Uniscan::Google;
use Getopt::Std;

my $func = Uniscan::Functions->new();
my @urllist = ( );
my $scan;


getopts('u:f:i:o:hbqwsder', \%args);

$func->banner();
$func->CheckUpdate();

if($args{h}){
	$func->help();
}

if(!$args{u} && !$args{f} && !$args{i} && !$args{o}){
	$func->help();
}

if($args{u}){
	$func->check_url($args{u});
	push(@urllist, $args{u});
} 
elsif($args{f}){
	open(url_list, "<$args{f}") or die "$!\n";
	while(<url_list>){
		my $line = $_;
		chomp $line;
		$func->check_url($line);
		push(@urllist, $line);
	}
	close(url_list);
}
elsif($args{i} && $args{o}){
	$func->write("="x99);
	$func->write("| Bing:");
	my $bing = Uniscan::Bing->new();
	$bing->search($args{i});
	$func->write("| Site list saved in file sites.txt");
	$func->write("="x99);
	$func->write("| Google:");
	my $google = Uniscan::Google->new();
	$google->search($args{o});
	$func->write("| Site list saved in file sites.txt");
	$func->write("="x99);
}

elsif($args{i}){
	$func->write("="x99);
	$func->write("| Bing:");
	my $bing = Uniscan::Bing->new();
	$bing->search($args{i});
	$func->write("| Site list saved in file sites.txt");
}
elsif($args{o}){
	$func->write("="x99);
	$func->write("| Google:");
	my $google = Uniscan::Google->new();
	$google->search($args{o});
	$func->write("| Site list saved in file sites.txt");
	$func->write("="x99);
}
else{
    $func->help();
}

if($args{b}){
	&background();
	printf("Going to background with pid: [%d]\n", $$);
}


$|++;

$func->DoLogin();


foreach my $url (@urllist){

	$func->write("Scan date: " . $func->date());

	my $crawler = Uniscan::Crawler->new();
	$crawler->AddUrl($url);

	$func->write("="x99);
	$func->write("| Domain: $url");
	$func->GetServerInfo($url);
	$func->write("| IP: ". $func->GetServerIp($url));
	$func->INotPage($url);

	$func->write("="x99);

# start checks to feed the crawler

	if($args{q}) {
		$func->write("|\n| Directory check:");
		my @dir = $func->Check($url, "Directory");
		foreach my $d (@dir){
			$crawler->AddUrl($d);
		}
		@dir   = ();
	}

	if($args{w}) {
		$func->write("|" . " "x99);
		$func->write("| File check:");
		my @files = $func->Check($url, "Files");
		foreach my $f (@files){
			$crawler->AddUrl($f);
		}
		@files = ();
	}

	if($args{e}){
		$func->write("|\n| Check robots.txt:");
		foreach my $f ($crawler->CheckRobots($url)){
			$crawler->AddUrl($f);
		}
	}

# end of checks to feed the crawler




	if($args{d}){
		# crawler start
		$func->write("|\n| Crawler Started:");
		$crawler->loadPlugins();
		our @urls = $crawler->start();
		our @forms = $crawler->GetForms();
		foreach (@forms){
			push(@urls, $_);
		}
		# crawler end
		$crawler->Clear();
		$crawler = 0;
	}


	$scan = Uniscan::Scan->new() if(!$scan);

	if($args{d}){
		#start dinamic and static tests
		$func->write("="x99);
		$func->write("| Dynamic tests:");
		$scan->loadPluginsDynamic();
		$scan->runDynamic(@urls);
	}
	
	if($args{s}){
		$func->write("="x99);
		$func->write("| Static tests:");
		$scan->loadPluginsStatic();
		$scan->runStatic($url);
	}
	

	if($args{r}){
		use Uniscan::Stress;
		my $stress = Uniscan::Stress->new();
		$func->write("="x99);
		$func->write("| Stress tests:");
		$stress->loadPlugins();
		$stress->run($url);
	}
	
	$func->write("="x99);
	$func->write("Scan end date: " . $func->date() . "\n\n\n");

}










##############################################
# Function background
# This function put Uniscan to background mode
#
#
# Param: nothing
# Return: nothing
##############################################


sub background{
	
	$SIG{"INT"} = "IGNORE";
	$SIG{"HUP"} = "IGNORE";
	$SIG{"TERM"} = "IGNORE";
	$SIG{"CHLD"} = "IGNORE";
	$SIG{"PS"} = "IGNORE";
	our $pid = fork;
	exit if $pid;
	die "Fork problem: $!\n" unless defined($pid);
}
