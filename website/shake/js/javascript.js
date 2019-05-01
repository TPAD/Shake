


function _l(e){ console.log(":: " + e + " ::"); }

var height = $(window).height();
var width = $(window).width();

$(document).ready(function(){
	$("#landing").css('width',width);
	$("#landing").css('height',height-20);
});

/* RESIZE WINDOW */
window.addEventListener('resize',function()
	{
		var h = $(window).height();
		var w = $(window).width();
		$("#landing").css('width',w);
		$("#landing").css('height',h-20);
	})