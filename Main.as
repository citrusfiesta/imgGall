package {

	import flash.display.MovieClip;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.MouseEvent;
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

		var xmlLoader:URLLoader;

		var container:MovieClip;

		public function Main() {
			xmlLoader = new URLLoader();
			xmlLoader.load(new URLRequest("gallery.xml"));
			xmlLoader.addEventListener(Event.COMPLETE, processXML);

			//this.addEventListener(MouseEvent.CLICK, callFull);
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

			createContainer();
			loadThumbs();
		}

		function createContainer():void {
			container = new MovieClip();
			container.x = xStart;
			container.y = yStart;
			this.addChild(container);

			container.addEventListener(MouseEvent.CLICK, callFull);

		}

		// Loads thumbs from the XML file
		function loadThumbs():void {
			for (var i:int = 0; i < totalImages; i++) {
				var thumbLoader:Loader = new Loader();
				var thumbURL = xmlImgList[i].@THUMB;
				thumbLoader.load(new URLRequest(thumbURL));
				thumbLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, thumbLoaded);

				thumbLoader.name = i.toString();

				thumbLoader.x = xStart + (thumbWidth + xSpacing) * xCounter;
				thumbLoader.y = yStart + (thumbHeight + ySpacing) * yCounter;

				if (++xCounter >= columns) {
					xCounter = 0;
					yCounter++;
				}
			}
		}

		// Animates the tween motion. Call with setTimeout.
		function animateTween():void {
			var tween = new Tween (arguments[0], arguments[1], arguments[2], arguments[3], arguments[4],
				arguments[5], arguments[6]);
		}

		// Fired by Event.COMPLETE after thumb is loaded
		function thumbLoaded(e:Event):void {
			var thumbLoader:Loader = Loader(e.target.loader);
			thumbArray.push(thumbLoader);
			container.addChild(thumbLoader);
			// Start the animation after a delay
			setTimeout (animateTween, delay, thumbLoader, "y", Back.easeOut,
				thumbLoader.y + stage.stageHeight, thumbLoader.y, 0.4, true);
			// Increase the delay for the next loaded thumb
			delay += 34;
			// Set y position to below the screen, otherwise the thumb
			// will wait in its final y position for its animation to
			// start after [delay] milliseconds.
			thumbLoader.y = stage.stageHeight;
		}

		function callFull(e:MouseEvent):void {
			var fullLoader:Loader = new Loader();
			var fullURL = xmlImgList[e.target.name].@FULL;
			fullLoader.load(new URLRequest(fullURL));
			fullLoader.contentLoaderInfo.addEventListener(Event.INIT, fullLoaded);

			container.removeEventListener(MouseEvent.CLICK, callFull);
		}

		function fullLoaded (e:Event):void {
			var fullLoader:Loader = Loader(e.target.loader);
			addChild(fullLoader);
			// Next two lines not necessary. Picture is same size as stage, x and y as 0 is ok
			//fullLoader.x = (stage.stageWidth - fullLoader.width) / 2;
			//fullLoader.y = (stage.stageHeight - fullLoader.height) / 2;
			fullLoader.addEventListener(MouseEvent.CLICK, removeFull);
		}

		function removeFull(e:MouseEvent):void {
			var loader:Loader = Loader (e.currentTarget);
			loader.unload();
			this.removeChild(loader);
			container.addEventListener(MouseEvent.CLICK, callFull);
		}
	}
}