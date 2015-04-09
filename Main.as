package {
	
	import flash.display.MovieClip;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.display.Loader;
	import flash.display.Sprite;
	
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
				//var sprite:Sprite = new Sprite();
				var thumbLoader:Loader = new Loader();
				thumbLoader.load(new URLRequest(xmlImgList[i].@THUMB));
				
				thumbLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, thumbLoaded);
				//thumbArray.push(thumbLoader.load(new URLRequest(xmlImgList[i].@THUMB)));
				//thumbArray.push(thumbLoader);
			}
		}
		
		function thumbLoaded(e:Event):void {
			trace("thumbLoaded() called");
			//var thumb:Loader = Loader(e.target.loader);
			//addChild(thumb);
			trace(thumbArray[0]);
		}
	}	
}