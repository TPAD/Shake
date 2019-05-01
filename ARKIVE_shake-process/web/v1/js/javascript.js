

/* JUST ADDED! --> NOT FUNCTIONAL (TO MY KNOWLEDGE) */


var limitX = 100, limitY = 100;
var containerW = $(document).width();
var containerH = $(document).height();
$( document ).mousemove(function( e ) {
  var mouseY = Math.min(e.clientY/(containerH*.01), limitY);
  var mouseX = Math.min(e.clientX/(containerW*.01), limitX);
  if(e.clientY<290) {
    $('.eye').css('top', mouseY+'%');
  }
  if(e.clientX<520) {
    $('.eye').css('left', mouseX+'%');   
  }
});