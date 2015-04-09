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
		var delayIncrement:int = 34;

		var columns:int;
		var xStart:int;
		var yStart:int;
		var xSpacing:int;
		var ySpacing:int;
		var thumbWidth:int;
		var thumbHeight:int;
		var xmlImgList:XMLList;
		var totalImages:int;
		var columnCounter:int;
		var rowCounter:int;

		var xmlLoader:URLLoader;
		// Holds the thumbs. Without this, this code doesn't work
		var container:MovieClip;

		public function Main() {
			xmlLoader = new URLLoader();
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

			createContainer();
			loadThumbs();

			// Removing event listener after its purpose is served
			xmlLoader.removeEventListener(Event.COMPLETE, processXML);
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
				thumbArray.push(thumbLoader);
				thumbLoader.name = i.toString();
			}

			animateGridIn();
		}

		function shuffleArray(pArray:Array):Array {
			var resultArray:Array = new Array();
			var randPos:int;
			for (var i:int = 0, n:int = pArray.length; i < n; i++) {
				randPos = int(Math.random() * pArray.length);
				resultArray.push(pArray.splice(randPos, 1)[0]);
			}
			return resultArray;
		}

		// After thumb is loaded, add it to the stage and remove its event listener
		function thumbLoaded(e:Event):void {
			var thumbLoader:Loader = Loader(e.target.loader);
			container.addChild(thumbLoader);
			thumbLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, thumbLoaded);
		}

		function callFull(e:MouseEvent):void {
			var fullLoader:Loader = new Loader();
			var fullURL = xmlImgList[e.target.name].@FULL;
			fullLoader.load(new URLRequest(fullURL));
			animateGridOut(fullLoader);
			fullLoader.contentLoaderInfo.addEventListener(Event.INIT, fullLoaded);

			container.removeEventListener(MouseEvent.CLICK, callFull);
		}

		function fullLoaded (e:Event):void {
			var fullLoader:Loader = Loader(e.target.loader);
			addChild(fullLoader);
			// Next two lines not necessary. Picture is same size as stage, x and y as 0 is ok
			//fullLoader.x = (stage.stageWidth - fullLoader.width) / 2;
			//fullLoader.y = (stage.stageHeight - fullLoader.height) / 2;
			fullLoader.y = stage.stageHeight;
			fullLoader.addEventListener(MouseEvent.CLICK, removeFull);
			fullLoader.contentLoaderInfo.removeEventListener(Event.INIT, fullLoaded);
		}

		function removeFull(e:MouseEvent):void {
			var loader:Loader = Loader (e.currentTarget);
			loader.unload();
			this.removeChild(loader);
			container.addEventListener(MouseEvent.CLICK, callFull);
			animateGridIn();
		}

		// Starts the animating of the tweens. Call with setTimeout.
		function animateTween():void {
			// If any objects were invisible, now they can be made visible again.
			arguments[0].visible = true;
			var tween = new Tween (arguments[0], arguments[1], arguments[2], arguments[3], arguments[4],
				arguments[5], arguments[6]);
		}

		function animateGridOut(loader:Loader):void {
			delay = 0;
			thumbArray = shuffleArray(thumbArray);
			for (var i:int = 0, n:int = thumbArray.length; i < n; i++) {

				setTimeout (animateTween, delay, thumbArray[i], "y", Back.easeIn,
					thumbArray[i].y, stage.stageHeight, 0.4, true);

				delay += delayIncrement;
			}
			delay += 400;
			setTimeout (animateTween, delay, loader, "y", Back.easeOut,
				loader.y - stage.stageHeight, loader.y, 0.4, true);
		}

		// Tweens the thumbs into place from below the bottom of the screen, one after the other
		function animateGridIn():void {
			// Set the counters to 0 so that the thumbs will be spawned at the correct positions
			columnCounter = 0;
			rowCounter = 0;
			// Shuffle the thumbs around so they are random each time
			thumbArray = shuffleArray(thumbArray);
			// Give each thumb their final positions for after the animation is done
			for (var i:int = 0; i < totalImages; i++) {

				thumbArray[i].x = xStart + (thumbWidth + xSpacing) * columnCounter;
				thumbArray[i].y = yStart + (thumbHeight + ySpacing) * rowCounter;
				// If we're at the last column, start a new row
				if (++columnCounter >= columns) {
					columnCounter = 0;
					rowCounter++;
				}
			}
			// Shuffle the array again so that the thumbs are animated in in a random order
			thumbArray = shuffleArray(thumbArray);
			// Reset the delay
			delay = 0;
			// Call the animations for all the thumbs
			for (i = 0; i < totalImages; i++) {
				// Start the animation after a set amount of time
				setTimeout (animateTween, delay, thumbArray[i], "y", Back.easeOut,
					stage.stageHeight, thumbArray[i].y, 0.4, true);
				// Increment that set amount of time for the next thumb in the array
				delay += delayIncrement;
				// Make the thumbs invisible because they are already in final position
				thumbArray[i].visible = false;
			}
		}

	}
}