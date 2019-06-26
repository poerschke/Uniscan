#!/usr/bin/env perl

#    Uniscan Web Vulnerability Scanner
#    Copyright (C) 2012  Douglas Poerschke Rocha
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Development Team:
#
#	 Douglas Poerschke Rocha since version 1.0


use FindBin qw($RealBin);
use lib $RealBin;
use Uniscan::Crawler;
use Uniscan::Functions;
use Uniscan::Scan;
use Uniscan::Bing;
use Uniscan::Google;
use Uniscan::FingerPrint;
use Uniscan::FingerPrint_Server;
use Uniscan::Configure;
use Uniscan::Http;
use Getopt::Std;

my $cfg = Uniscan::Configure->new(conffile => "uniscan.conf");
my %conf = $cfg->loadconf();
my $func = Uniscan::Functions->new();
my @urllist = ( );
my $scan;
our @urls = ();
$|++;

getopts('u:f:i:o:hbqwsdergj', \%args);
$func->createHTML();
$func->banner();
#$func->CheckUpdate();

if($args{h}){
	$func->help();
}

if(!$args{u} && !$args{f} && !$args{i} && !$args{o}){
	$func->help();
}

if($args{u}){
	$args{u} = "http://" . $args{u} if($args{u} !~/^https?:\/\//);
	$args{u} .= "/" if($args{u} !~/\/$/);
	$func->check_url($args{u});
	push(@urllist, $args{u});
}
elsif($args{f}){
	open(my $url_list, "<", "$args{f}") or die "$!\n";
	while(<$url_list>){
		my $line = $_;
		chomp $line;
		$func->check_url($line);
		push(@urllist, $line);
	}
	close($url_list);
}
elsif($args{i} && $args{o}){
	$func->writeHTMLCategory($conf{'lang2'});
	$func->write("="x99);
	$func->write("| Bing:");
	$func->writeHTMLItem("Bing:<br>");
	my $bing = Uniscan::Bing->new();
	$bing->search($args{i});
	$func->write("| " . $conf{'lang3'});
	$func->writeHTMLValue($conf{'lang3'});
	$func->write("="x99);
	$func->writeHTMLItem("Google:<br>");
	$func->write("| Google:");
	my $google = Uniscan::Google->new();
	$google->search($args{o});
	$func->writeHTMLValue($conf{'lang3'});
	$func->write("| ". $conf{'lang3'});
	$func->write("="x99);
	$func->writeHTMLCategoryEnd();
}
elsif($args{i}){
	$func->writeHTMLCategory($conf{'lang2'});
	$func->write("="x99);
	$func->write("| Bing:");
	$func->writeHTMLItem("Bing Search:<br>");
	my $bing = Uniscan::Bing->new();
	$bing->search($args{i});
	$func->writeHTMLValue($conf{'lang3'});
	$func->write("| ". $conf{'lang3'});
	$func->writeHTMLCategoryEnd();
}
elsif($args{o}){
	$func->writeHTMLCategory($conf{'lang2'});
	$func->write("="x99);
	$func->writeHTMLItem("Google Search:<br>");
	$func->write("| Google:");
	my $google = Uniscan::Google->new();
	$google->search($args{o});
	$func->writeHTMLValue($conf{'lang3'});
	$func->write("| ". $conf{'lang3'});
	$func->write("="x99);
	$func->writeHTMLCategoryEnd();
}
else{
    $func->help();
}

if($args{b}){
	&background();
	printf( $conf{'lang1'} . ": [%d]\n", $$);
}




$func->DoLogin();


foreach my $url (@urllist){
	$func->createHTML();
	$func->write($conf{'lang4'} . ": " . $func->date(0));

# check redirect and fix it
	my $crawler = Uniscan::Crawler->new();
	$func->writeHTMLCategory($conf{'lang5'});
	if($conf{'redirect'} == 1){
		$url = $func->CheckRedirect($url);
		my $url_temp = $url;
		my $proto = "";
		if($url_temp =~ /http:\/\//){
			$proto = "http://";
		}
		else{ $proto = "https://"; }
		$url_temp =~s/https?:\/\///g;
		if(rindex($url_temp, '/') != index($url_temp, '/')){
			$url_temp = $proto . substr($url_temp, 0, index($url_temp, '/')+1);
			$crawler->AddUrl($url_temp);
		}
	}

	push(@urls, $url);
	$crawler->AddUrl($url);
	$func->write("="x99);
	$func->write("| ". $conf{'lang6'} .": $url");
	$func->writeHTMLItem($conf{'lang6'});
	$func->writeHTMLValue($url);
	my $time1 = time();
	$func->GetServerInfo($url);
	my $time2 = time();
	my $total_time = $time2 - $time1;

	if($total_time < 30){
		$func->write("| IP: ". $func->GetServerIp($url));
		$func->writeHTMLItem($conf{'lang7'} . ":");
		$func->writeHTMLValue($func->GetServerIp($url));
		$func->writeHTMLCategoryEnd();
		$func->INotPage($url);
		$func->write("="x99);
		# web fingerprint
		if($args{g}){
			my $webf = Uniscan::FingerPrint->new();
			$func->writeHTMLCategory($conf{'lang8'});
			$webf->fingerprint($url);
			$webf->bannergrabing($url);
			$func->writeHTMLCategoryEnd();
		}

		# server fingerprint
		if($args{j}){
			my $serverf = Uniscan::FingerPrint_Server->new();
			$func->writeHTMLCategory($conf{'lang9'});
			$serverf->fingerprintServer($url);
			$func->writeHTMLCategoryEnd();
		}

		# start checks to feed the crawler
		#DIRECTORY CHECKS
		$func->writeHTMLCategory($conf{'lang10'});
		if($args{q}) {
			$func->write("|\n| ". $conf{'lang11'} .":");
			$func->writeHTMLItem($conf{'lang11'} .":<br>");
			my $http = Uniscan::Http->new();
			my $req = $url . "uniscan" . int(rand(1000)) . "/";
			my $res = $http->HEAD($req);
			if($res->code !~/404/){
				$func->write("| ". $conf{'lang12'}. " $req " . $conf{'lang13'});
				$func->writeHTMLValue($conf{'lang12'}." $req " . $conf{'lang13'});
			}
			else {
				my @dir = $func->Check($url, "Directory");
				foreach my $d (@dir){
					$crawler->AddUrl($d);
				}
				@dir   = ();
			}
			$func->write("="x99);
		}
		#FILE CHECKS
		if($args{w}) {
			$func->write("|" . " "x99);
			$func->write("| ". $conf{'lang14'} .":");
			$func->writeHTMLItem($conf{'lang14'} . ":<br>");
			my $http = Uniscan::Http->new();
			my $req = $url . "uniscan" . int(rand(1000)) . "/";
			my $res = $http->HEAD($req);
			if($res->code !~/404/){
				$func->write("| " . $conf{'lang12'} ." $req " . $conf{'lang13'});
				$func->writeHTMLValue($conf{'lang12'} ." $req " . $conf{'lang13'});
			}
			else {
				my @files = $func->Check($url, "Files");
				foreach my $f (@files){
					$crawler->AddUrl($f);
				}
				@files = ();
			}
			$func->write("="x99);
		}
		#robots check
		if($args{e}){
			$func->write("|\n| ". $conf{'lang15'} .":");
			$func->writeHTMLItem($conf{'lang15'} .":<br>");
			foreach my $f ($crawler->CheckRobots($url)){
				$crawler->AddUrl($f);
			}

			$func->write("|\n| ". $conf{'lang144'} .":");
			$func->writeHTMLItem($conf{'lang144'} .":<br>");
			foreach my $f ($crawler->CheckSitemap($url)){
				$crawler->AddUrl($f);
			}

			$func->write("="x99);
		}
		# end of checks to feed the crawler

		if($args{d}){
			# crawler start
			$func->write("|\n| ". $conf{'lang16'} .":");
			$crawler->loadPlugins();
			@urls = $crawler->start();
			our @forms = $crawler->GetForms();
			foreach (@forms){
				push(@urls, $_);
			}
			# crawler end
			$crawler->Clear();
			$crawler = undef;
		}
		$func->writeHTMLCategoryEnd();
		$scan = Uniscan::Scan->new();
		if($args{d}){
			$func->writeHTMLCategory($conf{'lang17'});
			#start dinamic and static tests
			$func->write("="x99);
			$func->write("| ". $conf{'lang18'} .":");
			$scan->loadPluginsDynamic();
			$scan->runDynamic(@urls);
			$func->writeHTMLCategoryEnd();
		}

		if($args{s}){
			$func->writeHTMLCategory($conf{'lang19'});
			$func->write("="x99);
			$func->write("| ". $conf{'lang20'} .":");
			$scan->loadPluginsStatic();
			$scan->runStatic($url);
			$func->writeHTMLCategoryEnd();
		}
		$scan = undef;
		if($args{r}){
			use Uniscan::Stress;
			my $stress = Uniscan::Stress->new();
			$func->write("="x99);
			$func->writeHTMLCategory($conf{'lang21'});
			$func->write("| ". $conf{'lang22'} .":");
			$stress->loadPlugins();
			$stress->run(@urls);
			$func->writeHTMLCategoryEnd();
		}
		$func->write("="x99);
		$func->write( $conf{'lang23'} .": " . $func->date(1) . "\n\n\n");
	}
	else{
		$func->write("| [-] ". $conf{'lang24'});
	}
	@urls = ();
	$func->writeHTMLEnd();
	$func->MoveReport($url);
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
