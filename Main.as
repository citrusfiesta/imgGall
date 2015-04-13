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
	import flash.display.StageDisplayState;

	public class Main extends MovieClip {
		// Global reference to all the thumbnails
		var thumbArray:Array = new Array();
		// Global reference to the current full screen image
		var fullLoader:Loader;
		// Holds full image before it's supposed to be animated
		var fullLoaderCache:Loader;
		// Holds the index in the xml-list of the current full image. Used for scrolling trough full images
		var fullLoaderIndex:int;

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
		// Global reference to the language switch button
		var langBtn:Loader;

		// Used to pass paramaters to an event listener
		var functionPassParamsToEvent:Function;

		public function Main() {
			// Set to full screen
			stage.displayState = StageDisplayState.FULL_SCREEN;

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

			langBtn = new Loader();
			langBtn.load(new URLRequest(loadedXML.LANG.@LOCATION));

			var loader = new Loader();
			loader.load(new URLRequest(loadedXML.BG.@LOCATION));
			loader.contentLoaderInfo.addEventListener(Event.INIT, bgLoaded);

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

			loadBg(loadedXML);
			createContainer();
			loadThumbs();

			// Removing event listener after its purpose is served
			xmlLoader.removeEventListener(Event.COMPLETE, processXML);
		}

		function loadBg(loadedXML:XML):void {
			var loader:Loader = new Loader();
			loader.load(new URLRequest(loadedXML.BG.@LOCATION));
			loader.contentLoaderInfo.addEventListener(Event.INIT, bgLoaded);
			//addChild(loader);
		}

		function bgLoaded(e:Event):void {
			var loader:Loader = Loader(e.target.loader);
			addChildAt(loader, 0);
			loader.contentLoaderInfo.removeEventListener(Event.INIT, bgLoaded);
		}

		// Create the movie clip container that holds the thumbs
		function createContainer():void {
			thumbContainer = new MovieClip();
			thumbContainer.x = xStart;
			thumbContainer.y = yStart;
			this.addChild(thumbContainer);
		}

		// Loads thumbs from the XML file
		function loadThumbs():void {
			for (var i:int = 0, n:int = xmlImgList.length(); i < n; i++) {
				var thumbLoader:Loader = new Loader();
				var thumbURL = xmlImgList[i].@THUMB;
				thumbLoader.load(new URLRequest(thumbURL));
				thumbLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, thumbLoaded);
				thumbArray.push(thumbLoader);
				// Setting the name to the position in the list so that when the thumb is clicked
				// we have an index to get the full image at.
				thumbLoader.name = i.toString();
			}

			animateGridIn();
		}

		// After thumb is loaded, add it to the stage and remove its event listener
		function thumbLoaded(e:Event):void {
			var thumbLoader:Loader = Loader(e.target.loader);
			thumbContainer.addChild(thumbLoader);
			thumbLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, thumbLoaded);
		}

		// Loads the full image, animates the grid away, and animates the full image in
		function callFull(e:MouseEvent):void {
			// First use the cache to reference the loader while it's not yet loaded
			fullLoaderCache = new Loader();
			// fullLoaderIndex is set to the index of the thumb
			fullLoaderIndex = e.target.name;
			loadFull();
			// Start animating the grid away
			animateGridOut();

			thumbContainer.removeEventListener(MouseEvent.CLICK, callFull);
		}

		// Loads in the full image
		function loadFull():void {
			var fullURL;
			//Depending on which language we're using, load in the corresponding image
			if (nl)
				fullURL = xmlImgList[fullLoaderIndex].@FULL_NL;
			else
				fullURL = xmlImgList[fullLoaderIndex].@FULL_EN;

			fullLoaderCache.load(new URLRequest(fullURL));

			// Reset the position to 0,0 to be safe
			fullLoaderCache.x = 0;
			fullLoaderCache.y = 0;

			fullLoaderCache.contentLoaderInfo.addEventListener(Event.INIT, fullLoaded);
		}

		// Once the full image is loaded, add it to fullLoader (instead of fullLoaderCache)
		function fullLoaded (e:Event):void {
			fullLoader = Loader(e.target.loader);
			fullLoaderCache.contentLoaderInfo.removeEventListener(Event.INIT, fullLoaded);
		}

		// Loads in the next image in the list and tweens it in place
		function loadNext(e:TweenEvent):void {
			// Set the fullLoaderIndex to the next image in the list. Loop back to start if necessary.
			if (++fullLoaderIndex >= xmlImgList.length())
				fullLoaderIndex = 0;
			loadFull();
			// Start animating it in
			var tween:Tween = new Tween (fullLoader, "x", Back.easeOut,
				fullLoader.x + stage.stageWidth, fullLoader.x, tweenDuration, true);
			e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, loadNext);
		}

		// Loads in the previous image in the list and tweens it in place
		function loadPrev(e:TweenEvent):void {
			// Set the fullLoaderIndex to the previous image in the list. Loop back to end if necessary.
			if (--fullLoaderIndex < 0)
				fullLoaderIndex = xmlImgList.length() - 1;
			loadFull();
			// Start animating it in
			var tween:Tween = new Tween (fullLoader, "x", Back.easeOut,
				fullLoader.x - stage.stageWidth, fullLoader.x, tweenDuration, true);
			e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, loadPrev);
		}

		// Called when clicking on the next-button
		function goToNext(e:MouseEvent):void {
			// Animate the full image away
			var tween:Tween = new Tween (fullLoader, "x", Back.easeIn, fullLoader.x,
				fullLoader.x - stage.stageWidth, tweenDuration, true);
			tween.addEventListener(TweenEvent.MOTION_FINISH, loadNext);
		}

		// Called when clicking on the previous-button
		function goToPrev(e:MouseEvent):void {
			// Animate the full image away
			var tween:Tween = new Tween (fullLoader, "x", Back.easeIn, fullLoader.x,
				fullLoader.x + stage.stageWidth, tweenDuration, true);
			tween.addEventListener(TweenEvent.MOTION_FINISH, loadPrev);
		}

		// Called when clicking the menu button. Tweens the full image away to the top,
		// removes the buttons from the stage.
		function removeFull(e:MouseEvent):void {
			animateFullOut(true);
		}

		// Called when clicking the language button. Tweens full image away and loads in other language version
		function changeLanguage(e:MouseEvent):void {
			// Flip language boolean
			nl = !nl;
			animateFullOut(false);
		}

		// Tweens the full image to above the stage.
		//
		// toMenu: True: grid is loaded in. False: image reloaded, in new lang when called by changeLanguage().
		function animateFullOut(toMenu:Boolean):void {
			var tween:Tween = new Tween (fullLoader, "y", Back.easeIn, fullLoader.y,
					fullLoader.y - stage.stageHeight, tweenDuration, true);
			/*
			// Assign the animating away starts, remove the buttons
			functionPassParamsToEvent = showHideButtons(false);
			tween.addEventListener(TweenEvent.MOTION_START, functionPassParamsToEvent);
			// Need this to call the tween event in the previous line
			tween.start();
			*/
			// Once the tween is complete, continue with the rest of the animation
			if (toMenu)// Go to grid
				tween.addEventListener(TweenEvent.MOTION_FINISH, fullImgAnimatedAway);
			else// Reload image (in new language when called from changeLanguage())
				tween.addEventListener(TweenEvent.MOTION_FINISH, animateFullIn);
		}

		// Shows or hides the buttons based on provided paramater.
		// This weird setup (with the return type of Function) is so
		// that arguments can be passed when using event listeners.
		function showHideButtons(showButtons:Boolean):Function {

			return function(e:TweenEvent):void {
				if (showButtons) {
					// Check if the buttons are on the stage. If not, add them and their event listeners.
					if (!nextBtn.stage) {
						addChild(nextBtn);
						nextBtn.x = stage.stageWidth - nextBtn.width;
						nextBtn.y = stage.stageHeight - nextBtn.height;
						nextBtn.addEventListener(MouseEvent.CLICK, goToNext);
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
						prevBtn.addEventListener(MouseEvent.CLICK, goToPrev);
					}
					if (!langBtn.stage) {
						addChild(langBtn);
						langBtn.x = 0;
						langBtn.y = 0;
						langBtn.addEventListener(MouseEvent.CLICK, changeLanguage);
					}
				} else {
					// Check if the buttons are on the stage. If so, remove them and their event listeners.
					if (nextBtn.stage) {
						removeChild(nextBtn);
						nextBtn.removeEventListener(MouseEvent.CLICK, goToNext);
					}
					if (menuBtn.stage) {
						menuBtn.removeEventListener(MouseEvent.CLICK, removeFull);
						removeChild(menuBtn);
					}
					if (prevBtn.stage) {
						removeChild(prevBtn);
						prevBtn.removeEventListener(MouseEvent.CLICK, goToPrev);
					}
					if (langBtn.stage) {
						removeChild(langBtn);
						langBtn.removeEventListener(MouseEvent.CLICK, changeLanguage);
					}
				}
				// Remove event listeners
				if (e.currentTarget.hasEventListener(TweenEvent.MOTION_FINISH))
					e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, functionPassParamsToEvent);
				else if (e.currentTarget.hasEventListener(TweenEvent.MOTION_START))
					e.currentTarget.removeEventListener(TweenEvent.MOTION_START, functionPassParamsToEvent);
			};
		}

		// Once the full image is tweened away it can be unloaded and removed from the stage.
		// The thumb grid is then animated in.
		function fullImgAnimatedAway(e:TweenEvent):void {
			// Unload the full image and remove the loader from the stage
			fullLoader.unload();
			removeChild(fullLoader);
			// Remove the event listener
			e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, fullImgAnimatedAway);
			// Call the animation of the grid.
			animateGridIn();
		}

		// Called once the last thumb in the grid is animated in. Makes all the thumbs responsive to clicks.
		function makeGridActive(e:TweenEvent):void {
			thumbContainer.addEventListener(MouseEvent.CLICK, callFull);
			e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, makeGridActive);
		}

		// Called once last thumb in grid is animated away. Moves in the full image from the top.
		function animateFullIn(e:TweenEvent):void {
			loadFull();
			// Check if the full image is already added to stage (it shouldn't be) and add it if necessary
			if (!fullLoader.stage)
				addChild(fullLoader);
			// Animate it in place
			var tween:Tween = new Tween (fullLoader, "y", Back.easeOut,
				fullLoader.y - stage.stageHeight, fullLoader.y, tweenDuration, true);
			// After the animating in is done, add the buttons
			functionPassParamsToEvent = showHideButtons(true);
			tween.addEventListener(TweenEvent.MOTION_FINISH, functionPassParamsToEvent);
			// Remove the event listener
			e.currentTarget.removeEventListener(TweenEvent.MOTION_FINISH, animateFullIn);
		}

		// Main animating function. Animates one object. Call with setTimeout.
		//
		// arguments[0] to arguments[6] are the parameters passed in when creating a tween.
		// See the AS3 docs for the Tween class for more info.
		//
		// arguments[0]: The object to be tweened
		// arguments[1]: The property to be tweened
		// arguments[2]: The type of easing function used
		// arguments[3]: The starting value of the property to be tweened
		// arguments[4]: The final value of the property to be tweened
		// arguments[5]: The duration of the tween
		// arguments[6]: Boolean specifying to use seconds instead of frames
		// arguments[7]: Optional. Function to be called once tween is done.
		function animateTween():void {
			// If any objects were invisible, now they can be made visible again.
			arguments[0].visible = true;
			var tween = new Tween (arguments[0], arguments[1], arguments[2], arguments[3], arguments[4],
				arguments[5], arguments[6]);
			// If a functionPassParamsToEvent was passed, call it once the tween is done
			if (arguments[7]) {
				// Add image listener so we can wait for the last thumb to animate away
				tween.addEventListener(TweenEvent.MOTION_FINISH, arguments[7]);
			}
		}

		// Tweens the thumbs away to the bottom and tweens the full image in form the top
		function animateGridOut():void {
			// Shuffle the array so that the thumbs are animated in in a random order
			var tempArray = shuffleArray(thumbArray);
			// Reset the delay
			delay = 0;
			// Call the animations for all the thumbs
			for (var i:int = 0, n:int = tempArray.length; i < n; i++) {
				if (i + 1 != n) {
					// Start the animation after a set amount of time
					setTimeout (animateTween, delay, tempArray[i], "y", Back.easeIn,
						tempArray[i].y, stage.stageHeight, tweenDuration, true);
				} else {
					// If the last tween is being called, animate in the full image afterwards
					setTimeout (animateTween, delay, tempArray[i], "y", Back.easeIn, tempArray[i].y,
						stage.stageHeight, tweenDuration, true, animateFullIn);
				}
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
				if (i + 1 != n) {
					// Start the animation after a set amount of time
					setTimeout (animateTween, delay, tempArray[i], "y", Back.easeOut,
						stage.stageHeight, tempArray[i].y, tweenDuration, true);
				} else {
					setTimeout (animateTween, delay, tempArray[i], "y", Back.easeOut,
						stage.stageHeight, tempArray[i].y, tweenDuration, true, makeGridActive);
				}
				// Increment that set amount of time for the next thumb in the array
				delay += delayIncrement;
				// Make the thumbs invisible because they are already in their final position
				tempArray[i].visible = false;
			}
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
	}
}