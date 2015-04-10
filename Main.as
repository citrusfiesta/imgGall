package {

	import flash.display.MovieClip;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.Loader;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import flash.utils.*;

	public class Main extends MovieClip {

		var thumbArray:Array = new Array();

		var delay:int = 0;
		var delayIncrement:int = 34;

		var tweenDuration:Number = 0.4;

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

		var nl:Boolean = true;

		// Used to pass paramaters to an event listener
		var functionLastThumbAnimatedAway:Function;

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

		// Returns a new randomized array based on the array passed in.
		function shuffleArray(pArray:Array):Array {
			// Make a copy of the original array;
			var startArray:Array = pArray.concat();
			var resultArray:Array = new Array();

			var randPos:int;
			for (var i:int = 0, n:int = startArray.length; i < n; i++) {
				// Get a random index from the startArray
				randPos = int(Math.random() * startArray.length);
				// Remove the element at that index and it to the end of the new array
				resultArray.push(startArray.splice(randPos, 1)[0]);
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
			var fullURL;
			if (nl)
				fullURL = xmlImgList[e.target.name].@FULL_NL;
			else
				fullURL = xmlImgList[e.target.name].@FULL_ENG;
			fullLoader.load(new URLRequest(fullURL));
			animateGridOut(fullLoader);
			fullLoader.contentLoaderInfo.addEventListener(Event.INIT, fullLoaded);

			container.removeEventListener(MouseEvent.CLICK, callFull);
		}

		function fullLoaded (e:Event):void {
			var fullLoader:Loader = Loader(e.target.loader);
			addChild(fullLoader);
			// Keep the loader invisible until all the thumbs are animated away
			fullLoader.visible = false;
			fullLoader.addEventListener(MouseEvent.CLICK, removeFull);
			fullLoader.contentLoaderInfo.removeEventListener(Event.INIT, fullLoaded);
		}

		function removeFull(e:MouseEvent):void {
			// Get the reference to the loader that was clicked on
			var loader:Loader = Loader (e.currentTarget);
			container.addEventListener(MouseEvent.CLICK, callFull);
			var tween:Tween = new Tween(loader, "y", Back.easeIn,
					loader.y, loader.y - stage.stageHeight, tweenDuration, true);
			// Once the tween is complete, continue with the rest of the animation
			tween.addEventListener(TweenEvent.MOTION_FINISH, fullImgAnimatedAway);
		}

		function fullImgAnimatedAway(e:TweenEvent):void {
			// Get the loader that was animated by getting the event's current target (the tween)
			// and its reference to the object that is being tweened (the loader)
			var loader:Loader = Loader (e.currentTarget.obj);
			// Unload the loader and remove it from the stage
			loader.unload();
			this.removeChild(loader);
			// Remove the event listener
			e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, fullImgAnimatedAway);
			// Call the animation of the grid.
			animateGridIn();
		}

		// This function is built this way so that it can get extra parameters as an event listener
		function lastThumbAnimatedAway(loader:Loader):Function {

			return function(e:TweenEvent):void {
				// Set loader to visible
				loader.visible = true;
				var tween:Tween = new Tween (loader, "y", Back.easeOut,
					loader.y - stage.stageHeight, loader.y, tweenDuration, true);

				// Remove the event listener
				e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, functionLastThumbAnimatedAway);
			};
		}

		// Main animating function. Animates one object. Call with setTimeout.
		function animateTween():void {
			// If any objects were invisible, now they can be made visible again.
			arguments[0].visible = true;
			var tween = new Tween (arguments[0], arguments[1], arguments[2], arguments[3], arguments[4],
				arguments[5], arguments[6]);
			// If the loader of the full image is passed, start the animating in of it
			if (arguments[7] != null) {
				functionLastThumbAnimatedAway = lastThumbAnimatedAway(arguments[7]);
				// Add image listener so we can wait for the last thumb to animate away
				tween.addEventListener(TweenEvent.MOTION_FINISH, functionLastThumbAnimatedAway);
			}
		}

		function animateGridOut(loader:Loader):void {
			// Shuffle the array so that the thumbs are animated in in a random order
			var tempArray = shuffleArray(thumbArray);
			// Reset the delay
			delay = 0;
			// Call the animations for all the thumbs
			for (var i:int = 0, n:int = tempArray.length; i < n; i++) {
				if (i + 1 != n)
					// Start the animation after a set amount of time
					setTimeout (animateTween, delay, tempArray[i], "y", Back.easeIn,
						tempArray[i].y, stage.stageHeight, tweenDuration, true);
				// If it's the last thumb to be animated pass in full image loader so it can animating in
				else
					setTimeout (animateTween, delay, tempArray[i], "y", Back.easeIn,
						tempArray[i].y, stage.stageHeight, tweenDuration, true, loader);
				// Increment that set amount of time for the next thumb in the array
				delay += delayIncrement;
			}
		}

		// Tweens the thumbs into place from below the bottom of the screen, one after the other
		function animateGridIn():void {
			// Set the counters to 0 so that the thumbs will be spawned at the correct positions
			columnCounter = 0;
			rowCounter = 0;

			// Give each thumb their final positions for after the animation is done
			for (var i:int = 0, n:int = thumbArray.length; i < n; i++) {

				thumbArray[i].x = xStart + (thumbWidth + xSpacing) * columnCounter;
				thumbArray[i].y = yStart + (thumbHeight + ySpacing) * rowCounter;
				// If we're at the last column, start a new row
				if (++columnCounter >= columns) {
					columnCounter = 0;
					rowCounter++;
				}
			}
			// Shuffle the array so that the thumbs are animated in in a random order
			var tempArray = shuffleArray(thumbArray);
			// Reset the delay
			delay = 0;
			// Call the animations for all the thumbs
			for (i = 0; i < n; i++) {
				// Start the animation after a set amount of time
				setTimeout (animateTween, delay, tempArray[i], "y", Back.easeOut,
					stage.stageHeight, tempArray[i].y, tweenDuration, true);
				// Increment that set amount of time for the next thumb in the array
				delay += delayIncrement;
				// Make the thumbs invisible because they are already in final position
				tempArray[i].visible = false;
			}
		}
	}
}