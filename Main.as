package {

	import flash.display.MovieClip;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.display.Loader;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import flash.utils.*;

	public class Main extends MovieClip {

		var thumbArray:Array = new Array();

		var delay:int = 0;

		var columns:int;
		var xStart:int;
		var yStart:int;
		var xSpacing:int;
		var ySpacing:int;
		var thumbWidth:int;
		var thumbHeight:int;
		var xmlImgList:XMLList;
		var totalImages:int;
		var xCounter:int;
		var yCounter:int;

		var xmlLoader:URLLoader = new URLLoader();

		public function Main() {
			xmlLoader.load(new URLRequest("gallery.xml"));
			xmlLoader.addEventListener(Event.COMPLETE, processXML);
		}

		// Gets values from the XML file and starts loading the thumbs
		function processXML(e:Event):void {

			var loadedXML:XML = new XML(e.target.data);

			columns = loadedXML.@COLUMNS;
			xStart = loadedXML.@XSTART;
			yStart = loadedXML.@YSTART;
			xSpacing = loadedXML.@XSPACING;
			ySpacing = loadedXML.@YSPACING;
			thumbWidth = loadedXML.@WIDTH;
			thumbHeight = loadedXML.@HEIGHT;
			xmlImgList = loadedXML.IMAGE;
			totalImages = xmlImgList.length();

			loadThumbs();
		}

		// Loads thumbs from the XML file
		function loadThumbs():void {
			for (var i:int = 0; i < totalImages; i++) {
				var thumbLoader:Loader = new Loader();
				thumbLoader.load(new URLRequest(xmlImgList[i].@THUMB));

				thumbLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, thumbLoaded);
				thumbLoader.x = xStart + (thumbWidth + xSpacing) * xCounter;
				thumbLoader.y = yStart + (thumbHeight + ySpacing) * yCounter;

				if (++xCounter >= columns) {
					xCounter = 0;
					yCounter++;
				}
			}
		}

		// Animates the tween motion. Call with setTimeout.
		function animateTween() {
			var tween = new Tween (arguments[0], arguments[1], arguments[2], arguments[3], arguments[4],
				arguments[5], arguments[6]);
		}

		function thumbLoaded(e:Event):void {
			var thumbLoader:Loader = Loader(e.target.loader);
			thumbArray.push(thumbLoader);
			this.addChild(thumbLoader);
			// Start the animation after a delay
			setTimeout (animateTween, delay, thumbLoader, "y", Strong.easeOut,
				thumbLoader.y + stage.stageHeight, thumbLoader.y, 0.5, true);
			// Increase the delay for the next loaded thumb
			delay += 34;
			// Set y position to below the screen, otherwise the thumb
			// will wait in its final y position for its animation to
			// start after [delay] milliseconds.
			thumbLoader.y = stage.stageHeight;
		}
	}
}