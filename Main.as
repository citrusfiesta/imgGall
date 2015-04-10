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
		var btnLoader:URLLoader;
		var prevBtn:Loader;
		var nextBtn:Loader;
		var menuBtn:Loader;

		// Global reference to the full screen image
		var fullLoader:Loader;

		// Used to pass paramaters to an event listener
		var functionPassParamsToEvent:Function;

		public function Main() {
			xmlLoader = new URLLoader();
			xmlLoader.load(new URLRequest("gallery.xml"));
			xmlLoader.addEventListener(Event.COMPLETE, processXML);

			btnLoader = new URLLoader();
			btnLoader.load(new URLRequest("buttons.xml"));
			btnLoader.addEventListener(Event.COMPLETE, processNav);
		}

		// Loading in the buttons
		function processNav(e:Event):void {

			var loadedXML:XML = new XML(e.target.data);

			prevBtn = new Loader();
			prevBtn.load(new URLRequest(loadedXML.PREV.@LOCATION));

			nextBtn = new Loader();
			nextBtn.load(new URLRequest(loadedXML.NEXT.@LOCATION));

			menuBtn = new Loader();
			menuBtn.load(new URLRequest(loadedXML.MENU.@LOCATION));

			// Remove the event listener
			btnLoader.removeEventListener(Event.COMPLETE, processNav);
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
			fullLoader = new Loader();
			var fullURL;
			//Depending on which language we're using, load in the corresponding image
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
			fullLoader = Loader(e.target.loader);
			addChild(fullLoader);
			// Keep the loader invisible until all the thumbs are animated away
			fullLoader.visible = false;
			fullLoader.contentLoaderInfo.removeEventListener(Event.INIT, fullLoaded);
		}

		function removeFull(e:MouseEvent):void {
			// Debugging: Call this only after the grid is loaded
			container.addEventListener(MouseEvent.CLICK, callFull);
			var tween:Tween = new Tween(fullLoader, "y", Back.easeIn,
					fullLoader.y, fullLoader.y - stage.stageHeight, tweenDuration, true);
			// Before the animating away starts, remove the buttons
			functionPassParamsToEvent = showHideButtons(false);
			tween.addEventListener(TweenEvent.MOTION_FINISH, functionPassParamsToEvent);
			// Once the tween is complete, continue with the rest of the animation
			tween.addEventListener(TweenEvent.MOTION_FINISH, fullImgAnimatedAway);
		}

		// Shows or hides the buttons based on provided paramater.
		function showHideButtons(show:Boolean):Function {

			return function(e:TweenEvent):void {
				if (show) {
					// Check if the buttons are on the stage. If not, add them.
					if (!nextBtn.stage) {
						addChild(nextBtn);
						nextBtn.x = stage.stageWidth - nextBtn.width;
						nextBtn.y = stage.stageHeight - nextBtn.height;
					}
					if (!menuBtn.stage) {
						addChild(menuBtn);
						menuBtn.x = nextBtn.x - menuBtn.width;
						menuBtn.y = nextBtn.y;
						menuBtn.addEventListener(MouseEvent.CLICK, removeFull);
					}
					if (!prevBtn.stage) {
						addChild(prevBtn);
						prevBtn.x = menuBtn.x - prevBtn.width;
						prevBtn.y = nextBtn.y;
					}
				} else {
					// Check if the buttons are on the stage. If so, remove them.
					if (nextBtn.stage) {
						removeChild(nextBtn);
					}
					if (menuBtn.stage) {
						menuBtn.removeEventListener(MouseEvent.CLICK, removeFull);
						removeChild(menuBtn);
					}
					if (prevBtn.stage){
						removeChild(prevBtn);
					}
				}
				// Remove event listener
				e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, functionPassParamsToEvent);
			};
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
				// After the animating in is done, add the buttons
				functionPassParamsToEvent = showHideButtons(true);
				tween.addEventListener(TweenEvent.MOTION_FINISH, functionPassParamsToEvent);
				// Remove the event listener
				e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, functionPassParamsToEvent);
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
				functionPassParamsToEvent = lastThumbAnimatedAway(arguments[7]);
				// Add image listener so we can wait for the last thumb to animate 	away
				tween.addEventListener(TweenEvent.MOTION_FINISH, functionPassParamsToEvent);
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