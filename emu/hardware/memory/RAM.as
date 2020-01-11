package emu.hardware.memory 
{
	import emu.hardware.proto_Device;
	import com.memory.StringManip;
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class RAM extends proto_Device
	{
		private var data:Array;
		public function RAM(location:uint = 0, size:uint = 0xFFFF) 
		{
			super(location);
			data = [];
			var i:uint = 0;
			while (i < size) {
				data[i] = 0x0;
				i++
			}
			//trace(data);
		}
		
		/**
		 * Reads 8 bit value from single byte
		 * @param	from	read target - will be sanitized
		 * @return
		 */
		override public function read(from:uint):uint {
			if (from > data.length) {
				trace("Read out of bounds: " + from.toString());
				return 0;
			}
			return 0xFF & data[from];
		}
		
		/**
		 * Writes 8 bit value to single byte
		 * @param	to	target byte
		 * @param	value	8 bit value (will be sanitized)
		 */
		override public function write(to:uint, value:uint):void {
			if (to > data.length) {
				trace("Write out of bounds: " + to.toString() + " with data: " + value.toString() );
				return;
			}
			data[to] = 0xFF & value;
			//trace("Writing 0x" + StringManip.pad(value.toString(16), "0", 2) + " to address 0x" + StringManip.pad(to.toString(16), "0", 2) + ".");
			//trace(StringManip.pad(readWord(0).toString(16)));
		}
		//TODO: Add bit level functions, hook up all the Save and Load functions
		//TODO: Check no other non-OS functions are left unhooked
		//TODO: Design and implement graphics processing unit
		
		
		
		/**
		 * reads 32 bit value from 4 consecutive bytes of ram
		 * @param	from	starting value (high byte)
		 * @return
		 */
		override public function readWord(from:uint):uint {
			return uint(((data[from] << 24) | (data[from + 1] << 16) | (data[from + 2] << 8) | data[from + 3]
		));
		}
		
		/**
		 * Reads 16 bit value from 2 consecutive bytes of ram
		 * @param	from	starting value (high byte)
		 * @return
		 */
		override public function readHalf(from:uint):uint {
			return uint(((data[from] << 8) | (data[from])));
		}
		
		
		/**
		 * dumps contents of ram as a fuckoff long string. Params are backwards for convenience
		 * @param	to		stops dumping at this point
		 * @param	from	starts dumping at this point
		 * @param	perline	how many values to print per line label
		 * @return 	returns a string containing specified ram data
		 */
		override public function dump(to:int = -1, from:int = 0, perline:uint=0x10 ):String {
			to -= location;
			from -= location;
			var out:String = "";
			var i:uint = from;
			if (to == -1) {
				to = data.length;
			}
			while (i < to) {
				if (!(i % perline)) {
					out = out+"\n[0x" + StringManip.pad(i.toString(16), "0", 4) + "] ";
				}
				out = out + StringManip.pad(uint(data[i]).toString(16), "0", 2) + " ";
				i++;
			}
			return out;
		}
	}

}