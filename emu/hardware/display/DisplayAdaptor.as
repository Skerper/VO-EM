package emu.hardware.display 
{
	import com.debug.Console;
	import emu.hardware.mainboard.proto_Motherboard;
	import emu.hardware.proto_Device;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	/**
	 * Display adaptor for a 
	 * @author Elliott Smith [voidSkipper]
	 */
	public class DisplayAdaptor extends proto_Device
	{
		public var output:BitmapData;
		
		private var vram:ByteArray;
		private var invalidated:Array;
		private var brightness:uint = parseInt("001110000011100000111000", 2);
		private const BRIGHTNESS:uint = 0x2580;
		
		private const BOX_COLOUR:uint = 0x2581;
		private const BOX_X:uint = 0x2582;
		private const BOX_Y:uint = 0x2583;
		private const BOX_WIDTH:uint = 0x2584;
		private const BOX_HEIGHT:uint = 0x2585;
		private const BOX_TRIGGER:uint = 0x2586;
		private const box_rect:Rectangle = new Rectangle(0, 0, 120, 80);
		
		public function DisplayAdaptor(location:uint = 0x0, bus:proto_Motherboard = null) 
		{
			super(location, bus);
			//output = new BitmapData(240, 160, true, 0);
			invalidated = [];
			vram = new ByteArray();
			vram.length = 0x9FFF;
			vram[BRIGHTNESS] = 0x7; //default brigtness is max
			vram[BOX_X] = 0;
			vram[BOX_Y] = 0;
			vram[BOX_COLOUR] = 0;
			vram[BOX_TRIGGER] = 0;
			vram[BOX_WIDTH] = 120;
			vram[BOX_HEIGHT] = 80;
		}
		
		public function hook(screen:BitmapData):void {
			this.output = screen;
		}
		
		override public function write(to:uint, value:uint):void {
			vram[to] = value;
			invalidated.push(to);
		}
		
		override public function read(from:uint):uint {
			return vram[from];
		}
		
		override public function refresh(e:Event = null):void {
			var i:uint = 0;
			var j:uint;
			var cp:uint;
			var cc:uint;
			while (i < invalidated.length) {
				cp = invalidated[i];
				
				if (cp == BRIGHTNESS) {
					cc = vram[cp] & 0x7;
					brightness = (cc << 19) | (cc << 11) | (cc << 3);
					j = 0;
					while (j < 120 * 80) {
						if (vram[j] & 0x40) {
							invalidated.push(j);
						}
						j++;
					}
				}
				else if (cp < 0x2580) { //ie, if it's in the screen space
					cc = vram[cp];
					if (cc & 0x40) {
						output.setPixel32(uint(cp % 120), uint(cp / 120), 0xFF000000|brightness|((cc <<18) & 0xC00000) | ((cc << 12) & 0xC000) | ((cc << 6) & 0xC0));
					}
					else {
						output.setPixel32(uint(cp % 120), uint(cp / 120), 0);
					}
				}
				else if (cp == BOX_TRIGGER) {
					cc = vram[BOX_TRIGGER];
					if (cc) {
						blank(vram[BOX_X], vram[BOX_Y], vram[BOX_WIDTH], vram[BOX_HEIGHT], vram[BOX_COLOUR]);
						vram[BOX_TRIGGER] = 0;
					}
				}
				i++;
			}
			invalidated = [];
		}
		
		public function blank(x:uint = 0, y:uint = 0, width:uint = 120, height:uint = 80, col:uint = 0):void {
			if (width + x > 120) {
				width = 120 - x;
			}
			if (height + y > 80) {
				height = 80 - y;
			}
			box_rect.x = x;
			box_rect.y = y;
			box_rect.width = width;
			box_rect.height = height;
			if (col & 0x40) {
				output.fillRect(box_rect, 0xFF000000|brightness|((col <<18) & 0xC00000) | ((col << 12) & 0xC000) | ((col << 6) & 0xC0));
			}
			else {
				output.fillRect(box_rect, 0);
			}
			var i:uint = 0;
			while (i < height) {
				vram.position = x + i * 120 + y * 120;
				var j:uint = 0;
				while (j < width) {
					vram.writeByte(col);
					j++;
				}
				i++;
			}
		}
		
	}

}