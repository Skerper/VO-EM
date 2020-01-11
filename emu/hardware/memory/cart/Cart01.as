package emu.hardware.memory.cart 
{
	import com.debug.Console;
	import com.input.TextInput;
	import com.memory.StringManip;
	import emu.hardware.mainboard.proto_Motherboard;
	import emu.hardware.memory.BA_RAM;
	import emu.hardware.memory.ROM;
	import emu.hardware.proto_Device;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class Cart01 extends proto_Cartridge
	{
		public static const os_info:Rectangle = new Rectangle(0, 0, 25, 25);
		public static const os_label_bite:Rectangle = new Rectangle(0, 0, 25, 25);
		public static const os_label:Rectangle = new Rectangle(10, 10, 230, 180);
		public static const os_bank_0:Rectangle = new Rectangle(250, 10, 75, 75);
		public static const os_bank_1:Rectangle = new Rectangle(332, 10, 75, 75);
		public static const os_bank_2:Rectangle = new Rectangle(414, 10, 75, 75);
		public static const os_bank_3:Rectangle = new Rectangle(250, 95, 75, 75);
		public static const os_bank_4:Rectangle = new Rectangle(332, 95, 75, 75);
		public static const os_bank_5:Rectangle = new Rectangle(414, 95, 75, 75);
		public static const os_savedata:Rectangle = new Rectangle(272, 180, 195, 7); //4096 bytes of save data
		public static const BANK_OPACITY:uint = 0x80000000;
		public static const SHIMMER:uint = 0x10;
		
		public static const BANKS:Array = [os_bank_0, os_bank_1, os_bank_2, os_bank_3, os_bank_4, os_bank_5];
		
		public var banks:Array;
		public var meta:ROM;
		
		public static const BANK0:uint = 0;
		public static const BANK1:uint = 1;
		public static const BANK2:uint = 2;
		public static const BANK3:uint = 3;
		public static const BANK4:uint = 4;
		public static const BANK5:uint = 5;
		public static const SAVE:uint = 6;
		
		
		public var selected:uint = 1;
		
		public function Cart01(location:uint = 0x0, bus:proto_Motherboard = null) 
		{
			this.location = location;
			this.bus = bus;
			this.banks = [];
			var i:uint = 0;
			while (i < 6) {
				banks.push(new ROM(0, 0x4000));
				i++;
			}
			this.meta = new ROM();
			banks.push(new BA_RAM(0, 0x1000));
			this.info = new ROM(0xFFFF0000, 25 * 25 * 3);
		}
		
		override public function read(from:uint):uint {
			if (from < 0x4000) {
				return banks[0].read(from);
			}
			if (selected == SAVE && from > 0x5000) {
				Console.out("Attempted read from save data outside of save data bounds (" + from + ")");
				return 0;
			}
			if(selected < banks.length){
				return banks[selected].read(from - 0x4000);
			}
			return 0;
		}
		override public function write(to:uint, value:uint):void {
			trace("Cartridge write attempt...");
			if (to < 0x4000) {
				if (value > 6) {
					Console.out("Attempted to switch to nonexistent cartridge bank " + value);
					return;
				}
				selected = value;
				return;
			}
			if (to < 0x5000) {
				banks[SAVE].write(to - 0x4000, value);
				return;
			}
			if (value > 6) {
				Console.out("Attempted to switch to nonexistent cartridge bank " + value);
				return;
			}
			selected = value;
		}
		
		override public function loadData(data:Array):void {
			if (data[1] == "image") {
				loadImageCart(data[0]);
			}
			else if (data[1] == "text") {
				loadTextCart(data[0]);
			}
		}
		
		private function loadTextCart(d:String):void {
			var lines:Array = d.split("\n");
			var start:uint = 0x0;
			var raw:Array = [];
			var commands:Array = [];
			var i:uint = 0;
			while (i < lines.length) {
				if (lines[i] != "\r"&&lines[i]!="\n"&&lines[i]!="\r\n"){
					if (String(lines[i]).charAt(0) == ".") {
						commands.push(lines[i]);
					}
					else {
						raw.push(String(lines[i]).split("  "));
					}
				}
				i++;
			}
			i = 0;
			while (i < raw.length) {
				raw[i][0] = parseInt(String(raw[i][0]), 16);
				raw[i][1] = String(raw[i][1]).split(" ");
				i++;
			}
			i = 0;
			var j:uint = 0;
			var c:uint = 0;
			while (i < raw.length) {
				c = raw[i][0];
				j = 0;
				while (j < raw[i][1].length) {
					if (!isNaN(parseInt(raw[i][1][j], 16))) {
						//trace((c + j) / 0x4000);
						banks[Math.floor((c+j)/0x4000)].write((c%0x4000)+j, parseInt(raw[i][1][j], 16));
						//trace(c + j+", "+parseInt(raw[i][1][j], 16));
					}
					j++;
				}
				i++;
			}
			
			i = 0;
			while (i < BANKS.length) {
				banks[i].lock();
				i++;
			}
			var sign:Array = [0x56, 0x4F, 0x2D, 0x45, 0x4D];
			i = 0;
			while (i < sign.length) {
				info.write(i, uint(sign[i]));
				
				i++;
			}
			
			i = 0;
			while (i < commands.length) {
				commands[i] = String(commands[i]).split(" ");
				if (commands[i][0] == ".start") {
					info.writeWord(0x34, parseInt(String(commands[i][1]), 16));
				}
				i++;
			}
			info.lock();
		}
		
		private function loadImageCart(d:BitmapData):void {
			var i:uint = 0;
			var tb:BitmapData = new BitmapData(75, 75, true, 0);
			while (i < BANKS.length) {
				tb.fillRect(tb.rect, 0);
				var c:ROM = banks[i];
				tb.copyPixels(d, BANKS[i], new Point(), null, null, true);
				var j:uint = 0;
				while (j*3 < 0x4000) {
					var p:uint = tb.getPixel32(j % 75, j / 75);
					c.write(j * 3    , (p >> 16) & 0xFF);
					c.write(j * 3 + 1, (p >> 8 ) & 0xFF);
					c.write(j * 3 + 2,  p        & 0xFF);
					j++;
				}
				c.lock();
				i++;
			}
			
			tb = new BitmapData(25, 25, true, 0);
			tb.copyPixels(d, os_info, new Point, null, null, true);
			c = info;
			j = 0;
			while (j * 3 < 25 * 25 * 3) {
				p = tb.getPixel32(j % 25, j / 25);
				//trace(p.toString(16));
				c.write(j * 3    , (p >> 16) & 0xFF);
				c.write(j * 3 + 1, (p >> 8 ) & 0xFF);
				c.write(j * 3 + 2,  p        & 0xFF);
				j++;
			}
			info.lock();
			j = 0;
			var ts:String = "Cartridge info dump:\n";
			while (j < 0x40) {
				if (j&&!(j % 16)) {
					ts = ts + "\n";
				}
				ts = ts + StringManip.pad(info.read(j).toString(16), "0", 2) + " ";
				
				j++;
			}
			//trace(ts);
			
			//trace(dump(0x7999, 0, 0x10, true));

		}
	}
	
	
}