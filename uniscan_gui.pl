#!/usr/bin/perl
use Tk;




my $dir= $0;
my $mw = MainWindow->new(); 
my $var1 = 1;
my $var2 = 1;
my $var3 = 1;
my $var4 = 1;
my $var5 = 1;
my $var6 = 1;
my $var7 = 1;
my $var8 = 1;


$mw->geometry("910x650");
$mw->minsize(qw(910 650));
$mw->maxsize(qw(910 650)); 
$mw->title("Uniscan Web Vulnerability Scanner");

$| = 1;


#widgets positions#
my $frame = $mw -> Frame()->pack(-side=>'top', -fill=>'x');  

##########
# url
##########
my $labelurl = $frame -> Label(-text=>"URL:") -> pack(-side => 'left', -expand => 0);
my $urlentry = $frame -> Entry(-width => 140)  -> pack(-side => 'left', -expand => 0);
my $url = $urlentry -> insert('end',"localhost");	

############
# options
###########
my $frameinfo = $mw->Frame()->place(-x => 0, -y => 30); 
my $opt = $frameinfo->Label(-text=>"Uniscan Options:")->pack(-side=>'left', -expand=>0);
my $chk = $frameinfo->Checkbutton(-text=>"Check Directory", -variable=>\$var1)->pack(-side=>'left', -expand=>0);
$chk->deselect();
my $chk2 = $frameinfo->Checkbutton(-text=>"Check Files", -variable=>\$var2)->pack(-side=>'left', -expand=>0);
$chk2->deselect();
my $chk3 = $frameinfo->Checkbutton(-text=>"Check /robots.txt", -variable=>\$var3)->pack(-side=>'left', -expand=>0);
$chk3->deselect();
my $chk4 = $frameinfo->Checkbutton(-text=>"Dynamic tests", -variable=>\$var4)->pack(-side=>'left', -expand=>0);
$chk4->deselect();

my $frameinfo2 = $mw->Frame()->place(-x => 0, -y => 55); 
my $opt2 = $frameinfo2->Label(-text=>"                                ")->pack(-side=>'left', -expand=>0);
my $chk5 = $frameinfo2->Checkbutton(-text=>"Static tests", -variable=>\$var5)->pack(-side=>'left', -expand=>0);
$chk5->deselect();
my $chk6 = $frameinfo2->Checkbutton(-text=>"Stress tests", -variable=>\$var6)->pack(-side=>'left', -expand=>0);
$chk6->deselect();
my $chk7 = $frameinfo2->Checkbutton(-text=>"Web Fingerprint", -variable=>\$var7)->pack(-side=>'left', -expand=>0);
$chk7->deselect();
my $chk8 = $frameinfo2->Checkbutton(-text=>"Server Fingerprint", -variable=>\$var8)->pack(-side=>'left', -expand=>0);
$chk8->deselect();



##########
# start
##########
my $f;
my $start = $mw -> Frame(-borderwidth=>1)->place(-x => 0, -y => 75);
my $botaostart = $start -> Button(-text => 'Start scan', -command => sub { $f = $mw->Frame(-container=>1, -borderwidth=>1)->place(-x=>0, -y=>110, -width=>900, -height=>600); open_x($f);})->pack(-fill =>'y', -fill =>'x', -side => 'left',-expand => 0);

my $log = $mw -> Frame(-borderwidth=>1)->place(-x => 100, -y => 75);
my $botaolog = $log -> Button(-text => 'Open log file', -command => sub { open_log(); })->pack(-fill =>'y', -fill =>'x', -side => 'left',-expand => 0);








MainLoop;


sub open_log(){
    my $kwrite = `which kwrite`;
    my $gedit = `which gedit`;
    chomp $kwrite;
    chomp $gedit;
    if(-x $kwrite){
        system("$kwrite uniscan.log &");
    }
    elsif(-x $gedit){
        system("$gedit uniscan.log &");
    }
    else{
        my $mw1 = MainWindow->new();
        $mw1->geometry("910x650");
        $mw1->minsize(qw(910 650));
        $mw1->maxsize(qw(910 650)); 
        $mw1->title("Uniscan Web Vulnerability Scanner - Log file uniscan.log");
        my $form = $mw1->Frame(-relief=>'groove')->pack(-side=>'left');
        my $txt = $form->Text(-width=>125, -height => 43)->pack(-side=>'left');
        my $scly = $form->Scrollbar(-orient=>'v', -command=>[yview=>$txt]);
        my $sclx = $form->Scrollbar(-orient=>'h', -command=>[xview=>$txt]);
        $txt->configure(-yscrollcommand => ['set', $scly], -xscrollcommand => ['set', $sclx]);
        $txt->grid(-row=>1, -column=>1);
        $scly->grid(-row=>1, -column=>2, -sticky=>'ns');
        $sclx->grid(-row=>2, -column=>1, -sticky=>'ew');
        $form->grid(-row=>5, -column=>1, -columnspan=>2);
        open(my $file, "<", "uniscan.log") or die "$!\n";
        my @lines = <$file>;
        close($file);
        foreach my $line (@lines){
            $txt->insert('end', $line);
        }
    }
}


sub open_x(){
    my ($frame) = @_;
    my $id = sprintf hex $frame->id;
    my $t = $mw->Toplevel(-use => $id);
    my $str = "-u " . $urlentry->get();
    $str .= " -q" if($var1 == 1);
    $str .= " -w" if($var2 == 1);
    $str .= " -e" if($var3 == 1);
    $str .= " -d" if($var4 == 1);
    $str .= " -s" if($var5 == 1);
    $str .= " -r" if($var6 == 1);
    $str .= " -g" if($var7 == 1);
    $str .= " -j" if($var8 == 1);
    system("xterm -geometry 149x40 -into $id -e \"perl uniscan.pl $str \" &");
}



