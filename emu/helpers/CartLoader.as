package emu.helpers 
{
	import emu.hardware.cpu.CPU;
	import emu.hardware.memory.cart.Cart01;
	import emu.hardware.proto_Device;
	import flash.display.BitmapData;
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class CartLoader
	{
		
		public function CartLoader() 
		{
			
		}
		
		public static function loadCart(target:proto_Device, data:String, cpu:CPU = null):void {
			var lines:Array = data.split("\n");
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
					if(!isNaN(parseInt(raw[i][1][j], 16))){
						target.write(c+j, parseInt(raw[i][1][j], 16));
						//trace(c + j+", "+parseInt(raw[i][1][j], 16));
					}
					j++;
				}
				i++;
			}
			
			if (cpu != null) {
				i = 0;
				while (i < commands.length) {
					commands[i] = String(commands[i]).split(" ");
					if (commands[i][0] == ".start") {
						cpu.setPC(parseInt(String(commands[i][1]), 16));
					}
					i++;
				}
			}
		}
		
		public static function Cart01DebugLoader(data:String, target:Cart01, cpu:CPU):void {
			
		}
		
	}

}