package emu.hardware.memory.cart 
{
	import emu.hardware.mainboard.proto_Motherboard;
	import emu.hardware.memory.ROM;
	import emu.hardware.proto_Device;
	
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class proto_Cartridge extends proto_Device
	{
		public var info:ROM = new ROM(0, 4);
		public function proto_Cartridge(location:uint = 0x0, bus:proto_Motherboard = null) 
		{
			super(location, bus);
			
		}
		
	}

}