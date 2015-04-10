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
		// Global reference to all the thumbnails
		var thumbArray:Array = new Array();
		// Global reference to the current full screen image
		var fullLoader:Loader;

		// Holds the thumbs. Without this, this code doesn't work
		var thumbContainer:MovieClip;

		// delay is used time the animations one after the other
		var delay:int = 0;
		// The difference in delay between the start of the animations
		var delayIncrement:int = 34;
		// How long the tweens last
		var tweenDuration:Number = 0.4;

		// Loads in the gallery XML file
		var xmlLoader:URLLoader;
		// How many columns the grid of thumbs has. Set in the xml-file
		var columns:int;
		// The horizontal starting position of the grid. Set in the xml-file
		var xStart:int;
		// The vertical starting position of the grid. Set in the xml-file
		var yStart:int;
		// The horizontal spacing between the thumbs. Set in the xml-file
		var xSpacing:int;
		// The vertical spacing between the thumbs. Set in the xml-file
		var ySpacing:int;
		// Self-explanatory. Set in the xml-file
		var thumbWidth:int;
		// Self-explanatory. Set in the xml-file
		var thumbHeight:int;
		// The list of objects with IMAGE tags in the XML file. Used to load the thumbs
		var xmlImgList:XMLList;

		// Boolean that handles which images are loaded in (with English or Dutch descriptions)
		var nl:Boolean = true;
		// Loads in the buttons xml-file
		var btnLoader:URLLoader;
		// Global reference to the prev button
		var prevBtn:Loader;
		// Global reference to the next button
		var nextBtn:Loader;
		// Global reference to the menu button
		var menuBtn:Loader;

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

			// Assign all the variables for the thumbs
			columns = loadedXML.@COLUMNS;
			xStart = loadedXML.@XSTART;
			yStart = loadedXML.@YSTART;
			xSpacing = loadedXML.@XSPACING;
			ySpacing = loadedXML.@YSPACING;
			thumbWidth = loadedXML.@WIDTH;
			thumbHeight = loadedXML.@HEIGHT;
			xmlImgList = loadedXML.IMAGE;

			createContainer();
			loadThumbs();

			// Removing event listener after its purpose is served
			xmlLoader.removeEventListener(Event.COMPLETE, processXML);
		}

		// Create the movie clip container that holds the thumbs
		function createContainer():void {
			thumbContainer = new MovieClip();
			thumbContainer.x = xStart;
			thumbContainer.y = yStart;
			this.addChild(thumbContainer);

			thumbContainer.addEventListener(MouseEvent.CLICK, callFull);
		}

		// Loads thumbs from the XML file
		function loadThumbs():void {
			for (var i:int = 0, n:int = xmlImgList.length(); i < n; i++) {
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
			thumbContainer.addChild(thumbLoader);
			thumbLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, thumbLoaded);
		}

		// Loads the full image and calls its animation
		function callFull(e:MouseEvent):void {
			fullLoader = new Loader();
			var fullURL;
			//Depending on which language we're using, load in the corresponding image
			if (nl)
				fullURL = xmlImgList[e.target.name].@FULL_NL;
			else
				fullURL = xmlImgList[e.target.name].@FULL_ENG;
			fullLoader.load(new URLRequest(fullURL));
			// Start animating the grid away
			animateGridOut(fullLoader);
			fullLoader.contentLoaderInfo.addEventListener(Event.INIT, fullLoaded);

			thumbContainer.removeEventListener(MouseEvent.CLICK, callFull);
		}

		// Once the full image is loaded it is added to the stage but set to invisible.
		// This is while the thumbs are animated away. The last thumb that is tweened
		// will call the animation to tween in the full image.
		function fullLoaded (e:Event):void {
			fullLoader = Loader(e.target.loader);
			addChild(fullLoader);
			// Keep the loader invisible until all the thumbs are animated away
			fullLoader.visible = false;
			fullLoader.contentLoaderInfo.removeEventListener(Event.INIT, fullLoaded);
		}

		// Tweens the full image away to the top, removes the buttons from the stage.
		function removeFull(e:MouseEvent):void {
			// Debugging: Call this only after the grid is loaded
			thumbContainer.addEventListener(MouseEvent.CLICK, callFull);
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

		// Once the full image is tweened away it can be unloaded and removed from the stage.
		// The thumb grid is then animated in.
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

		// Tweens the thumbs away to the bottom and tweens the full image in form the top
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
			// Aids in the horizontal placement of the thumbs
			var columnCounter:int = 0;
			// Aids in the vertical placement of the thumbs
			var rowCounter:int = 0;

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
				// Make the thumbs invisible because they are already in their final position
				tempArray[i].visible = false;
			}
		}
	}
}