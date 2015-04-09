package {

	import flash.display.MovieClip;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.display.Loader;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;

	public class Main extends MovieClip {

		var thumbArray:Array = new Array();


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

		function thumbLoaded(e:Event):void {
			var thumbLoader:Loader = Loader(e.target.loader);
			thumbArray.push(thumbLoader);
			this.addChild(thumbLoader);
			var tween:Tween = new Tween (thumbLoader, "y", Back.easeOut, thumbLoader.y + stage.stageHeight,
				thumbLoader.y, 0.5, true);
		}
	}
}