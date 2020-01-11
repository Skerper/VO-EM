package emu.hardware 
{
	import emu.hardware.proto_Device;
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class NullDevice extends proto_Device
	{
		
		public function NullDevice() 
		{
			super();
		}
		
		override public function read(from:uint):uint {
			trace("Read operation attempted from unmapped memory address 0x" + from.toString(16));
			return 0;
		}
		
		override public function write(to:uint, value:uint):void {
			trace("Attempted to write 0x" + value.toString(16) + " to unmapped address 0x" + to.toString());
		}
	}

}