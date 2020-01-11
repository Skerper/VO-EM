

<head>
	<title>VO-EM :: A 32bit Virtual Game Console</title>
	<style>
	img { 
		image-rendering: optimizeSpeed;             /* STOP SMOOTHING, GIVE ME SPEED  */
		image-rendering: -moz-crisp-edges;          /* Firefox                        */
		image-rendering: -o-crisp-edges;            /* Opera                          */
		image-rendering: -webkit-optimize-contrast; /* Chrome (and eventually Safari) */
		image-rendering: pixelated; /* Chrome */
		image-rendering: optimize-contrast;         /* CSS3 Proposed                  */
		-ms-interpolation-mode: nearest-neighbor;   /* IE8+                           */
		image-rendering: pixelated;                  /* CSS3 Actual                    */
	}
	body {
		font-family: "Lucida Console", Monaco, monospace;
	}
	</style>
</head>
<body>
	<?php 
	//include('media/header.php');
	$show = "VO-EM_Debugger";
	if(isset($_GET['show']){
		if($_GET['show'] == "cartridge"){
			$show = "VO-EM_Exporter";
		}
		else if($_GET['show'] == "editor"){
			$show = "VO-EM_Editor";
		}
	}
	?>
	
	<p>
		<object type="application/x-shockwave-flash" 
		  data="media/VO-EM_Debugger.swf" 
		  width="800" height="400">
		  <param name="movie" value="media/<?php print $show; ?>.swf" />
		  <param name="quality" value="low"/>
		</object>
	</p>
<body>
