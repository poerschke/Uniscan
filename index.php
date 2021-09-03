<?php
error_reporting(E_ERROR | E_WARNING | E_PARSE);	
$action = $_GET["action"];

if($action == "scan"){

	$url = $_POST['url'];

	if(preg_match("#;|\||&|%#", $url)){ die("Bad, very bad, this characters are not accepted: ; | & %");}
	$str =  "./uniscan.pl -b -u " . $url;

	foreach ($_POST['options'] as $key => $value) {
		if(preg_match("#;|\||&|%#", $value)){
			die("Bad, very bad, this characters are not accepted: ; | & %");
		}
		$str .= $value;
	}

        $str .= " > /dev/null &";
	$a = shell_exec($str);
	sleep(10);
	header('Location: report/uniscan.html');

}
else if($action == "search"){
	$google = $_POST["google"];
	$bing = $_POST["bing"];
	if(preg_match("#;|\||&|%#", $google)){ die("Bad, very bad, this characters are not accepted: ; | & %");}
	if(preg_match("#;|\||&|%#", $bing)){ die("Bad, very bad, this characters are not accepted: ; | & %");}
	$cmd = "perl uniscan.pl ";
	if($bing !== ""){
	    $cmd = $cmd . " -i $bing";
	}
	
	if($google !== ""){
	    $cmd = $cmd . " -o $google";
	}
	echo "<pre>";
	system($cmd);
	echo "</pre>";
	
}
else{
?> 

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Uniscan Web Client</title>
<link href="report/css.css" rel="stylesheet" />
</head>

<body>
<center><img src="report/images/logo.png"></center><br>
<center><a href="report/index.php">See reports</a></center><br><br><br>
   		<form action="index.php?action=search" method="post">
        <fieldset>
        <legend>Search Engine</legend>
        <label for="google">Google:<input id="google" type="text" name="google" /></label>
  		<label for="bing">Bing:<input id="bing" type="text" name="bing" /></label>
  		<input type="submit" value="Send" /><input type="reset" value="Reset">
        </fieldset>
        </form>
<br><br>
		<form action="index.php?action=scan" method="post">
        <fieldset>
        <legend>Scan Options</legend>
		<label for="dir"><input id="dir" type="checkbox" name="options[]" value=" -q" checked="checked" /> Directory Check</label>
		<label for="fil"><input id="fil" type="checkbox" name="options[]" value=" -w" checked="checked" /> File Check</label>
		<label for="rob"><input id="rob" type="checkbox" name="options[]" value=" -e" checked="checked" /> /robots.txt Check</label>
		<label for="dyn"><input id="dyn" type="checkbox" name="options[]" value=" -d" checked="checked" /> Dynamic Tests</label>
		<label for="sta"><input id="sta" type="checkbox" name="options[]" value=" -s" checked="checked" /> Static Tests</label>
		<label for="str"><input id="str" type="checkbox" name="options[]" value=" -r" checked="checked" /> Stress Tests</label>
		<label for="web"><input id="web" type="checkbox" name="options[]" value=" -g" checked="checked" /> Web Server Information</label>
		<label for="ser"><input id="ser" type="checkbox" name="options[]" value=" -j" checked="checked" /> Server Information</label>
        </fieldset>
        <fieldset>
		<legend>Target:</legend>
        <label for="ur">URL:<input id="ur" type="text" name="url" value="http://www.site.com/" /></label>
		<input type="submit" value="Start Scan" />
		<input type="reset" value="Reset">
        </fieldset>
		</form>
</body>
</html>



<?php 
}
?>
