package
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.PNGEncoderOptions;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.Security;
	import flash.system.System;
	import flash.utils.ByteArray;
	
	public class PixelArtConverter extends Sprite
	{
		private var _sprite : Sprite;
		private var _imgBytes : ByteArray;
		private var _movieWidth : Number;
		private var _movieHeight : Number;
		private var _swfLoader : Loader;
		
		public function PixelArtConverter()
		{
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		protected function onAddedToStage(event:Event):void
		{
			_sprite = new Sprite();
			_sprite.graphics.beginFill(0x00ff33,1);
			_sprite.graphics.drawRect(0,0,stage.stageWidth, stage.stageHeight);
			_sprite.graphics.endFill();
			addChild(_sprite);
			
			this.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER,onDragIn);
			this.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,onDrop);
		}
		protected function draw(mc:MovieClip): BitmapData
		{
			var numFrames : int = mc.totalFrames;
			var i : int;
			var imgWidth : int = 0;
			var imgHeight : int = 0;
			var frame : int;

			// draw the sprite sheet
			var bmd : BitmapData = new BitmapData(_movieWidth * numFrames, _movieHeight, true, 0x00000000);
			var bmp : Bitmap = new Bitmap(bmd);
			for(i  = 0; i < numFrames; i++)
			{
				frame = i + 1;
				mc.gotoAndStop(frame);
				var m : Matrix = new Matrix();
				m.tx = i * _movieWidth;
				m.ty = 0;
				bmd.draw(mc, m);
			}
			addChild(bmp);
			mc.y = _movieHeight;
			return bmd;
			//stage.quality = StageQuality.HIGH;
		}
		protected function onDragIn(event:NativeDragEvent):void
		{
			NativeDragManager.acceptDragDrop(this);
		}
		protected function onDrop(event:NativeDragEvent):void
		{
			var clip : Clipboard = event.clipboard;  
			var object : Object = clip.getData(ClipboardFormats.FILE_LIST_FORMAT);  
			var request : URLRequest = new URLRequest(object[0].url);  
			_swfLoader = new Loader();
			_swfLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSWFLoadComplete);
			_swfLoader.load(request);
		}
		protected function saveData(event:Event):void 
		{
			var newFile:File = event.target as File;
			var stream:FileStream = new FileStream();
			stream.open(newFile, FileMode.WRITE);
			stream.writeBytes(_imgBytes);
			stream.close();

		}
		protected function onSWFLoadComplete(event:Event):void
		{
			_swfLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSWFLoadComplete);
			_movieWidth = _swfLoader.contentLoaderInfo.width;
			_movieHeight = _swfLoader.contentLoaderInfo.height;
			
			var mc : MovieClip = event.currentTarget.content;
			var bmd : BitmapData = draw(mc);
			
			_imgBytes = new ByteArray();
			bmd.encode(bmd.rect,new PNGEncoderOptions(), _imgBytes);
			var docsDir:File = File.documentsDirectory;
			try
			{
				docsDir.browseForSave("Save As");
				docsDir.addEventListener(Event.SELECT, saveData);
			}
			catch (error:Error)
			{
				trace("Failed:", error.message);
			}
		}
	}
}