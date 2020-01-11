package emu.hardware
{
	import emu.hardware.memory.ROM;
	import flash.events.Event;
	import emu.hardware.mainboard.proto_Motherboard;
	import com.memory.StringManip;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class proto_Device
	{
		public var location:uint;
		public var bus:proto_Motherboard;
		public var size:uint;
		
		public function proto_Device(location:uint = 0x0, bus:proto_Motherboard = null):void {
			this.location = location;
			this.bus = bus;
		}
		
		public const CTRL_IEN:uint = 	parseInt("000000000000000001000000", 2);
		public const CTRL_IPR_M:uint = 	parseInt("111111110000000000000000", 2);
		public const CTRL_IPR0:uint = 	parseInt("000000010000000000000000", 2);
		public const CTRL_IPR1:uint = 	parseInt("000000100000000000000000", 2);
		public const CTRL_IPR2:uint = 	parseInt("000001000000000000000000", 2);
		public const CTRL_IPR3:uint = 	parseInt("000010000000000000000000", 2);
		public const CTRL_IPR4:uint = 	parseInt("000100000000000000000000", 2);
		public const CTRL_IPR5:uint = 	parseInt("001000000000000000000000", 2);
		public const CTRL_IPR6:uint = 	parseInt("010000000000000000000000", 2);
		public const CTRL_IPR7:uint = 	parseInt("100000000000000000000000", 2);
		
		/**
		 * Reads 8 bit value from single byte
		 * @param	from	read target - will be sanitized
		 * @return
		 */
		public function read(from:uint):uint {
			return 0;
		}
		/**
		 * Writes 8 bit value to single byte
		 * @param	to	target byte
		 * @param	value	8 bit value (will be sanitized)
		 */
		public function write(to:uint, value:uint):void {
		}
		
		
		
		/**
		 * reads 32 bit value from 4 consecutive bytes of ram
		 * @param	from	starting value (high byte)
		 * @return
		 */
		public function readWord(from:uint):uint {
			return uint(((read(from) << 24) | (read(from + 1) << 16) | (read(from + 2) << 8) | read(from + 3)
		));
		}
		
		/**
		 * Reads 16 bit value from 2 consecutive bytes of ram
		 * @param	from	starting value (high byte)
		 * @return
		 */
		public function readHalf(from:uint):uint {
			return uint((read(from + 2) << 8) | read(from + 3));
		}
		
		/**
		 * writes 32 bit value to 4 consecutive bytes of ram
		 * @param	to	starting value
		 * @param	value	32 bit uint
		 */
		public function writeWord(to:uint, values:uint):void {
			write(to, values >> 24);
			write(to + 1, values >> 16);
			write(to + 2, values >> 8);
			write(to + 3, values);
		}
		
		public function writeHalf(to:uint, values:uint):void {
			write(to, values >> 8);
			write(to + 1, values);
		}
		
		public function refresh(e:Event = null):void {
			
		}
		
		public function IRQ(irq:uint):void {
			if ((irq & CTRL_IEN) && (irq & CTRL_IPR_M)) {
				bus.cpu.requestInterrupt(irq & CTRL_IPR_M);
			}
		}
		
		public function loadData(data:Array):void {
			
		}
		

		
		/**
		 * dumps contents of ram as a fuckoff long string. Params are backwards for convenience
		 * @param	to		stops dumping at this point
		 * @param	from	starts dumping at this point
		 * @param	perline	how many values to print per line label
		 * @return 	returns a string containing specified ram data
		 */
		public function dump(to:int = -1, from:int = 0, perline:uint=0x10, absolute:Boolean = true):String {
			var out:String = "Dumping device memory:\n";
			var i:uint = from;
	
			if (to == -1) {
				trace("Did blind dumping crash the VM? That's because I never tested it! Hahahahah. Check proto_Device.dump() for more funtimes!");
				to = this.size;
			}
			while (i < to) {
				if (!(i % perline)) {
					out = out+"\n[0x" + StringManip.pad(i.toString(16), "0", 4) + "] ";
				}
				out = out + StringManip.pad(uint(read(i)).toString(16), "0", 2) + " ";
				i++;
			}
			return out;
		}
	}
}