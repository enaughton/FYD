<?php
function bezier($p,$steps)
{
   $t = 1 / $steps;
   $temp = $t * $t;
   $ret = array();
   $f = $p[0];
   $fd = 3 * ($p[1] - $p[0]) * $t;
   $fdd_per_2=3*($p[0]-2*$p[1]+$p[2])*$temp;
   $fddd_per_2=3*(3*($p[1]-$p[2])+$p[3]-$p[0])*$temp*$t;
   $fddd = $fddd_per_2 + $fddd_per_2;
   $fdd = $fdd_per_2 + $fdd_per_2;
   $fddd_per_6 = $fddd_per_2 * (1.0 / 3);
   for ($loop=0; $loop<$steps; $loop++) 
   {
       array_push($ret,$f);
       $f = $f + $fd + $fdd_per_2 + $fddd_per_6;
       $fd = $fd + $fdd + $fddd_per_2;
       $fdd = $fdd + $fddd;
       $fdd_per_2 = $fdd_per_2 + $fddd_per_2;
   }
   return $ret;
}

function rand_string($len = 10) 
{
	$e = base64_encode(pack("h*", sha1(mt_rand())));
	return substr(strtr($e, "+/=", "xyz"), 0, $len);
}

function hex2dec($hex)
{
	$color = str_replace('#', '', $hex);
	$ret = array(
		'r' => hexdec(substr($color, 0, 2)),
		'g' => hexdec(substr($color, 2, 2)),
		'b' => hexdec(substr($color, 4, 2))
	);
	return $ret;
}

session_start();

if (  isset($_REQUEST['captcha']) )
{
	$font_name = 'tahoma.ttf';
	$font_size = 11;
	$a = imageftbbox($font_size+3, 0, $font_name, "W");
	$l_width = $a[2];	

	switch (@$GLOBALS["FORM"]["_captcha"])
	{
	default:
		$_SESSION['cpw'] = strtoupper(rand_string(6));
		$code = $_SESSION['cpw'];
		$circles = 3;
		$height = 35;
		$width = 120;	
		$image = imagecreate($width, $height);
		$background_color = imagecolorallocate ($image, 0, 0, 0);
		$image2 = imagecreate($width, $height);
		imagecolorallocate ($image2, 0, 0, 0);
		$r=0.01;$g=0.51;$b=0.87;	
		for ($i=1;$i<=$circles;$i++) {
			$value = rand(200, 255);
			$randomcolor = imagecolorallocate ($image2 , $value*$r, $value*$g,$value*$b);
			imagefilledellipse($image2,rand(0,$width-10),rand(0,$height-3),rand(20,70),rand(20,70), $randomcolor);
		}
		ImageCopyMerge($image, $image2, 1, 0, 0, 0, $width, $height, 50);
		$tcc = hex2dec('#C0C0C');
		$tc = ImageColorAllocate($image, $tcc['r'], $tcc['g'], $tcc['b']);	
		for($i=0; $i<strlen($code); $i++)
			imagettftext($image, rand($font_size-3, $font_size+3), rand(-25,25), 12+$l_width*$i, 22, $tc, $font_name, $code[$i]);
	break;
	case "0":
		$_SESSION['cpw'] = (string)rand(111111, 999999);
		$code = $_SESSION['cpw'];
		$circles = 3;
		$height = 35;
		$width = 120;	
		$image = imagecreate($width, $height);
		$background_color = imagecolorallocate ($image, 0, 0, 0);
		$image2 = imagecreate($width, $height);
		imagecolorallocate ($image2, 0, 0, 0);
		$r=0.01;$g=0.97;$b=0.51;	
		for ($i=1;$i<=$circles;$i++) {
			$value = rand(100, 255);
			$randomcolor = imagecolorallocate ($image2 , $value*$r, $value*$g,$value*$b);
			imagefilledellipse($image2,rand(0,$width-10),rand(0,$height-3),rand(20,70),rand(20,70), $randomcolor);
		}
		ImageCopyMerge($image, $image2, 1, 0, 0, 0, $width, $height, 50);
		$tcc = hex2dec('#FFC0C');
		$tc = ImageColorAllocate($image, $tcc['r'], $tcc['g'], $tcc['b']);	
		for($i=0; $i<strlen($code); $i++)
			imagettftext($image, rand($font_size-3, $font_size+8), rand(-35,35), 12+$l_width*$i, 22, $tc, $font_name, $code[$i]);
	break;
	case "1":
		$font_name = 'tahoma.ttf';
		$font_size = 16;
		$_SESSION['cpw'] = strtoupper(rand_string(6));
		$code = $_SESSION['cpw'];
		$height = 32;
		$width = 120;	
		$image = imagecreate($width, $height);
		$bgc = hex2dec('#CCCCCC');
		$bg = ImageColorAllocate($image, $bgc['r'], $bgc['g'], $bgc['b']);
		$dcc = hex2dec('#999999');
		$dc = ImageColorAllocate($image, $dcc['r'], $dcc['g'], $dcc['b']);
		for($i=0; $i<($width*$height)/5; $i++) 
				imagefilledellipse($image, mt_rand(0,$width), mt_rand(0,$height), 1, 1, $dc);
		$tcc = hex2dec('#000000');
		$tc = ImageColorAllocate($image, $tcc['r'], $tcc['g'], $tcc['b']);	
		for($i=0; $i<strlen($code); $i++)
			imagettftext($image, $font_size, 0, 12+$l_width*$i, rand(15, 30), $tc, $font_name, $code[$i]);	
	break;
	case "3":
		$_SESSION['cpw'] = rand_string(6);
		$code = $_SESSION['cpw'];
		$height = 32;
		$font_size = 16;
		$width = 120;	
		$image = imagecreate($width, $height);
		$bgc = hex2dec('#6495ED');
		$bg = ImageColorAllocate($image, $bgc['r'], $bgc['g'], $bgc['b']);
		
		
		$image2 = imagecreate($width, $height);
		imagecolorallocate ($image2, 0, 0, 0);
		$r=1;$g=1;$b=1;	
		for ($i=1;$i<=8;$i++) {
			$value = rand(100, 255);
			$randomcolor = imagecolorallocate ($image2 , $value*$r, $value*$g,$value*$b);
			imagefilledrectangle($image2,rand(0,$width-10),rand(0,$height-3),rand(20,70),rand(20,70), $randomcolor);
		}
		ImageCopyMerge($image, $image2, 1, 0, 0, 0, $width, $height, 50);
		
		$tcc = hex2dec('#000000');
		$tc = ImageColorAllocate($image, $tcc['r'], $tcc['g'], $tcc['b']);	
		for($i=0; $i<strlen($code); $i++)
			imagettftext($image, $font_size, rand(-25,25), 12+$l_width*$i, 22, $tc, $font_name, $code[$i]);
			
		$image2 = imagecreate($width, $height);
		imagecolorallocate ($image2, 255, 255, 255);
		for($kk=0; $kk<10; $kk++)
		{
			$x=array(10,rand(-300,300),8,100);
			$y=array(5,rand(-300,300),4,80);			
			$by = bezier($y,50);
			$bx = bezier($x,50);			
			$tc = imagecolorallocate ($image2, 200, 200,200);
			for($i=0;$i<49;$i++)
			   imageline($image2,$bx[$i],$by[$i],$bx[$i+1],$by[$i+1],$tc);
		}
		ImageCopyMerge($image, $image2, 1, 0, 0, 0, $width, $height, 25);
	break;
	
	}
	
	header("Expires: Wed, 1 Jan 1997 00:00:00 GMT");
	header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
	header("Cache-Control: no-store, no-cache, must-revalidate");
	header("Cache-Control: post-check=0, pre-check=0", false);
	header("Pragma: no-cache");
	header("Content-type: image/png");
	imagepng($image);
	imagedestroy($image);
	exit;
}

?>
