package emu.hardware.display 
{
	import adobe.utils.CustomActions;
	import com.visual.BitmapDrawing;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class Display extends Sprite
	{
		public var glowpanels:Array;
		public var composite:Sprite;
		public var overlay:BitmapData;
		public function Display(screens:Array, glows:Array, bg:uint = 0xFF000000, width:uint = 240, height:uint = 160)  
		{
			//this.addChild(new Bitmap(new BitmapData(width, height, true, bg)));
			var i:uint = 0;
			this.glowpanels = [];
			this.overlay = new BitmapData(120, 80, true, 0);
			this.composite = new Sprite();
			this.addChild(composite);
			//this.addChild(new Bitmap(new BitmapData(width, height, true, 0xFF000000))); 
			composite.addChild(new Bitmap(new BitmapData(240, 160, false, 0xFF000000)));
			while (i < screens.length) {
				//var c:Bitmap = new Bitmap(glows[i]);
				composite.addChild(new Bitmap(screens[i]));
				//this.addChild(c);
				//c.filters = [new BlurFilter(2, 2, BitmapFilterQuality.HIGH)];
				//c.blendMode = BlendMode.ADD;
				i++;
			}
			var olb:Bitmap = new Bitmap(overlay);
			olb.scaleX = 2;
			olb.scaleY = 2;
			composite.addChild(olb);
		}
		
		public function reScreen(screens:Array):void {
			this.removeChild(composite);
			this.composite = new Sprite();
			var i:uint = 0;
			while (i < screens.length) {
				//var c:Bitmap = new Bitmap(glows[i]);
				composite.addChild(new Bitmap(screens[i]));
				//this.addChild(c);
				//c.filters = [new BlurFilter(2, 2, BitmapFilterQuality.HIGH)];
				//c.blendMode = BlendMode.ADD;
				i++;
			}
		}
		
	}

}