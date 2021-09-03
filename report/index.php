<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Uniscan Reports</title>
<link href="css.css" rel="stylesheet" />
</head>

<body>

<div>
<center><img src="images/logo.png"></center><br>
<center><a href="../index.php">Back to engine</a></center><br><br><br>
<table align="center" cellspacing="2">
<tr>
<td><b>Host</b></td>
<td width="30"><b>RFI</b></td>
<td width="30"><b>RCE</b></td>
<td width="30"><b>SQL-I</b></td>
<td width="30"><b>LFI</b></td>
<td width="30"><b>XSS</b></td>
<td width="70"><b>Blind SQL-I</b></td>
<td width="50"><b>Web Shell</b></td>
<td width="50"><b>PHP CGI</b></td>
<td width="70"><b>FCK Editor</b></td>
<td width="50"><b>Timthumb</b></td>
<td width="50"><b>phpinfo()</b></td>
<td width="70"><b>Source Code</b></td>
<td width="70"><b>Upload Form</b></td>
<td width="150"><b>Date</b></td>

</tr>


<?php

if ($handle = opendir('.')) {
    while (false !== ($entry = readdir($handle))) {
        if ($entry != "." && $entry != "..") {
			if(preg_match("#\.html$#", $entry)){
					echo "<tr>";
					echo "<td><a href='$entry'>". substr($entry, 0, -5) ."</a></td>\n"; 
					get_icon($entry, "RFI");
					get_icon($entry, "RCE");
					get_icon($entry, "SQL-I");
					get_icon($entry, "LFI");
					get_icon($entry, "XSS");
					get_icon($entry, "BSQL-I");
					get_icon($entry, "WEBSHELL");
					get_icon($entry, "PHPCGI");
					get_icon($entry, "FCKEDITOR");
					get_icon($entry, "TIMTHUMB");
					get_icon($entry, "PHPINFO");
					get_icon($entry, "SOURCECODE");
					get_icon($entry, "UPLOADFORM");
					echo "<td>" . date ("F d Y H:i:s.", filemtime($entry)) . "</td>\n";
					echo "</tr>";
			}
        }
    }
    closedir($handle);
}
?>

</table>
</div>
</body>
</html>


<?php

function get_icon($filename, $string){

	$handle = fopen($filename, "r");
	$content = fread($handle, filesize ($filename));
	fclose($handle);
	if(preg_match("#<!--". $string ."-->#", $content)){
		echo "<td><a href='$filename#$string'><img src='images/IconV.png'></a></td>\n";
	}
	else{
	//
		echo "<td><img src='images/IconF.png'></td>\n";
	}
}

?>