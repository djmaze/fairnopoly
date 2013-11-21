$(function() {
	target = 0;
	if(window.location.hash){
	  target = $(window.location.hash).index('.Accordion-item');
	}
	$(".accordion-anchor").click(function() {
	  link = $(event.target).attr('href');
	  target = $(link).index('.Accordion-item');
	  $(".Accordion--activated").accordion({
	    animate: false,
	    active: target
    });
	});

	$(".Accordion").accordion({
		header: "a.Accordion-header",
		heightStyle: "content",
		collapsible: true,
		animate: 200,
		active: false
	});

	$(".Accordion--activated").accordion({
		header: "a.Accordion-header",
		heightStyle: "content",
		collapsible: true,
		animate: 200,
		active: target
	});

	$(".Accordion--containsArticles").on("accordionactivate", function(event,ui) { $('.l-ArticleList').masonry(); });

	$(".Accordion--scrollToActive").on("accordionactivate", function(event,ui) {
		if(ui.newHeader.length != 0) {
	    	$('html, body').animate({
	        	scrollTop: ui.newHeader.offset().top
	    	}, 100);
    	}
     });
	$(".Accordion").removeClass("ui-accordion ui-widget ui-helper-reset");
	$(".Accordion-header").removeClass("ui-accordion-header ui-helper-reset ui-state-default ui-accordion-header-active ui-corner-top ui-accordion-icons ui-state-focus");
	$(".Accordion-header span").removeClass("ui-accordion-header-icon ui-icon ui-icon-triangle-1-s");


});