package emu.hardware.mainboard
{
	import com.debug.Console;
	import com.memory.StringManip;
	import emu.hardware.memory.cart.proto_Cartridge;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import emu.hardware.cpu.CPU;
	import emu.hardware.display.Display;
	import emu.hardware.NullDevice;
	import emu.hardware.memory.ROM;
	import emu.hardware.proto_Device;
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class proto_Motherboard
	{
		public var cpu:CPU;
		public var cartridge:proto_Cartridge;
		private var world:Stage;
		public var clock:Timer;
		private var oblivion:NullDevice;
		public var display:Display;
		
		public var selectTarget:Function = selectTargetRegular;
		
		public var tickcount:uint;
		
		public function proto_Motherboard(stage:Stage) 
		{
			this.world = stage;
			this.clock = new Timer(1);
			this.oblivion = new NullDevice();
			Console.hook(com_peek, "peek", "peek [value] - Read the byte at [value]", false, false);
			Console.hook(com_poke, "poke", "poke [target] [value] - write [value] to [target]", false, false);
		}
		
		public function start(cart:Array):void {
			tickcount = 0;
		}
		
		public function tick(e:Event = null):void {
		
			tickcount++;
		}
		
		public function debugTick(e:Event = null):void {
			
			tickcount++;
		}
		
		public function readWord(from:uint):uint {
			if (from % 4) {
				trace("Misaligned read from 0x" + from.toString(16) + " attempted. Off by " + (from % 4));
				cpu.requestInterrupt(CPU.PSW_IME);
				return 0;
			}
			return selectTarget(from).readWord(from-selectTarget(from).location);
		}
		
		public function readHalf(from:uint):uint {
			if (from % 2) {
				trace("Misaligned read 0x" + from.toString(16) + " attempted. Off by " + (from % 2));
				cpu.requestInterrupt(CPU.PSW_IME);
				return 0;
			}
			return selectTarget(from).readHalf(from-selectTarget(from).location);
		}
		
		public function readByte(from:uint):uint {
			return selectTarget(from).read(from-selectTarget(from).location);
		}
		
		public function unprotectedReadByte(from:uint):uint {
			return selectTargetUnsafe(from).read(from - selectTargetUnsafe(from).location);
		}
		
		public function writeWord(to:uint, value:uint):void {
			if (to % 4) {
				trace("Misaligned write to 0x" + to.toString(16) + " attempted. Off by " + (to % 4));
				cpu.requestInterrupt(CPU.PSW_IME);
				return;
			}
			//trace("Writing 0x"+value.toString(16)+"to location 0x" + (to-selectTarget(to).location).toString(16)+".");
			selectTarget(to).writeWord(to-selectTarget(to).location, value);
		}
		
		public function writeHalf(to:uint, value:uint):void {
			if (to % 2) {
				trace("Misaligned write to 0x" + to.toString(16) + " attempted. Off by " + (to % 4));
				cpu.requestInterrupt(CPU.PSW_IME);
				return;
			}
			selectTarget(to).writeHalf(to-selectTarget(to).location, value);
		}
		
		public function writeByte(to:uint, value:uint):void {
			selectTarget(to).write(to-selectTarget(to).location, value);
		}
		
		
		/**
		 * Routing for normal operation 
		 * @param	address
		 * @return
		 */
		public function selectTargetRegular(address:uint):proto_Device {
			return oblivion;
		}
		
		public function selectTargetUnsafe(address:uint):proto_Device {
			return oblivion;
		}
		
		public function switchTargetSelector(index:uint):void {
			
		}
		
		public function reset():void {
			
		}
		
		public function dump(from:uint = 0, length:uint = 0x100, perline:uint = 16):String {
			var o:String = "";
			var i:uint = 0;
			while (i < length) {
				if (!(uint(i+from) % (perline))) {
					o = o + "\n[" + StringManip.pad(uint(i+from).toString(16))+"] ";
				}
				if (cpu.PC == i + from) {
					o = o+"<"
				}
				else if (cpu.PC + 4 == i + from) {
					o = o+">"
				}
				else {
					o = o + " ";
				}
				o = o + StringManip.pad(unprotectedReadByte(i+from).toString(16), "0", 2);
				i++;
			}
			return o;
		}
		
		public function com_poke(args:Array):void {
			if (args.length < 3) {
				Console.out("Expected two args (target value)");
				return;
			}
			var i:uint = 2;
			//trace(args);
			while (i < args.length) {
				//trace( parseInt(String(args[1]), 16) + (i - 2) * 4, String(args[i]));
				writeByte(parseInt(String(args[1]), 16)+ i - 2, parseInt(String(args[i]), 16));
				i++;
			}
		}
		
		public function com_peek(args:Array):void {
			//trace(args, readByte(parseInt(String(args[1]), 16)))
			Console.out("Value: " + readByte(parseInt(String(args[1]), 16)));
		}
	}

}