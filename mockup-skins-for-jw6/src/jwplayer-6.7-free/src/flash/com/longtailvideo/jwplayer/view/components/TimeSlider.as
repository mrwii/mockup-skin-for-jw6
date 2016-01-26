package com.longtailvideo.jwplayer.view.components {
	import com.longtailvideo.jwplayer.events.ViewEvent;
	import com.longtailvideo.jwplayer.utils.RootReference;
	import com.longtailvideo.jwplayer.utils.Strings;
	import com.longtailvideo.jwplayer.view.interfaces.ISkin;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class TimeSlider extends Slider {
		private var _duration:Number;
		private var _tooltip:TooltipOverlay;
		private var _audioMode:Boolean = false;
		private var _controlbar:DisplayObject;
		private var _thumbnailImages:TooltipThumbnails;
		private var _cues:Array = [];
		private var _activeCue:Object;
		
		public function TimeSlider(name:String, skin:ISkin, controlbar:DisplayObject) {
			super(name, skin);
			
			_controlbar = controlbar;
			
			_duration = 0;
			_tooltip = new TooltipOverlay(skin);
			_tooltip.text = Strings.digits(_duration);
			_tooltip.alpha = 0;
			_tooltip.mouseEnabled = false;
			_tooltip.mouseChildren = false;
			
			_thumbnailImages = new TooltipThumbnails(skin);
			_thumbnailImages.addEventListener(Event.COMPLETE, thumbsLoaded);
			
			RootReference.stage.addChild(_tooltip);

			_clickArea.addEventListener(MouseEvent.MOUSE_OVER, overHandler);
			_clickArea.addEventListener(MouseEvent.MOUSE_OUT, outHandler);
			_clickArea.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
			
		}
		
		protected function addCue(pos:Number, text:String):void {
			var cueElem:Sprite = addElement("cue", true);
			var cue:Object = {
				position: pos,
				text: text,
				element: cueElem
			};
			_cues.push(cue);
			cueElem.addEventListener(MouseEvent.MOUSE_OVER, function():void { _activeCue = cue; });
			cueElem.addEventListener(MouseEvent.MOUSE_OUT, function():void { _activeCue = null; });
			cueElem.addEventListener(MouseEvent.CLICK, cueClickHandler);
			cueElem.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
			positionCues();
		}
		
		protected function cueClickHandler(evt:MouseEvent):void {
			dispatchEvent(new ViewEvent(ViewEvent.JWPLAYER_VIEW_CLICK, _activeCue.position / _duration));
		}

		protected function positionCues():void {
			for each (var cue:Object in _cues) {
				cue.element.x = (cue.position / _duration) * _width;
			}
			
		}
		
		public override function resize(width:Number, height:Number):void {
			super.resize(width, height);
			positionCues();
		}
		
		public function setDuration(d:Number):void {
			_duration = d;
			positionCues();
		}
		
		private function overHandler(evt:MouseEvent):void {
			if (!_audioMode) _tooltip.show();
		}

		var hideTimeout:Number;
		
		private function outHandler(evt:MouseEvent = null):void {
			hideTimeout = setTimeout(function():void {
				if (!_activeCue) hide();
			}, 100);
		}
		
		public function setThumbs(thumbs:String=null):void {
			if (thumbs) {
				_thumbnailImages.load(thumbs);
			} else {
				if (_tooltip.contains(_thumbnailImages)) _tooltip.removeChild(_thumbnailImages);
			}
		}
		
		public function setCues(cues:Array=null):void {	
			for each (var cue:Object in cues) {
				addCue(cue.begin,cue.text);
			}	
		}
		
		public function removeCues():void {	
			for each (var cue:Object in _cues) {
				removeChild(cue.element);
			}
			_cues = [];
		}
		
		private function thumbsLoaded(evt:Event):void {
			_tooltip.addChild(_thumbnailImages);
		}
		
		private function moveHandler(evt:MouseEvent):void {
			clearTimeout(hideTimeout);
			if (_duration > 0 || _duration <= -60) {
				RootReference.stage.setChildIndex(_tooltip, RootReference.stage.numChildren-1);
				if (_activeCue) {
					_tooltip.text = _activeCue.text;
				} else {
					var seconds:Number = Math.round(_duration * sliderPercent(evt.localX));
					if (_duration <= -60) {
						seconds = _duration - seconds;
						seconds = seconds > 0 ? 0 : seconds;
						_tooltip.text = "-" + Strings.digits((-1*seconds));
					}
					else {
						_tooltip.text = Strings.digits(seconds);
					}
				}
				_tooltip.x = evt.stageX;
				_tooltip.y = _controlbar.getBounds(RootReference.stage).y;
				_thumbnailImages.updateTimeline(seconds);
			}
		}
		
		public function audioMode(state:Boolean):void {
			_audioMode = state;
			if (_audioMode) outHandler();
		}
		
		public function hide():void {
			_tooltip.hide();
		}
		
	}
}