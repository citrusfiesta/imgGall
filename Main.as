package {

	import flash.display.MovieClip;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.display.Loader;

	public class Main extends MovieClip {

		var thumbArray:Array = new Array();


		var comlumns:int;
		var xOrigin:int;
		var yOrigin:int;
		var thumbWidth:int;
		var thumbHeight:int;
		var xmlImgList:XMLList;
		var totalImages:int;

		var xmlLoader:URLLoader = new URLLoader();

		public function Main() {
			xmlLoader.load(new URLRequest("gallery.xml"));
			xmlLoader.addEventListener(Event.COMPLETE, processXML);
		}

		function processXML(e:Event):void {

			var loadedXML:XML = new XML(e.target.data);

			comlumns = loadedXML.@COLUMNS;
			xOrigin = loadedXML.@XPOSITION;
			yOrigin = loadedXML.@YPOSITION;
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
				thumbLoader.x = thumbWidth * i;
			}
		}

		function thumbLoaded(e:Event):void {
			var thumbLoader:Loader = Loader(e.target.loader);
			thumbArray.push(thumbLoader);
			this.addChild(thumbLoader);
		}
	}
}