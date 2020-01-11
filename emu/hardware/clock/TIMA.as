package emu.hardware.clock 
{
	import emu.hardware.cpu.CPU;
	import emu.hardware.mainboard.proto_Motherboard;
	import emu.hardware.proto_Device;
	
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class TIMA extends proto_Device
	{
		private var countdown:uint;
		private var cpu:CPU;
		
		public function TIMA(location:uint = 0x0, bus:proto_Motherboard = null) 
		{
			super(location, bus);
			cpu = bus.cpu;
		}
		
		override public function read(from:uint):uint {
			switch(from) {
				case 0:
					return cpu.tick >> 24;
				break;
				case 1:
					return (cpu.tick >> 16) & 0xFF;
				break;
				case 2:
					return (cpu.tick >> 8) & 0xFF;
				break;
				case 3:
				    return cpu.tick & 0xFF;
				break;
				case 4:
					return cpu.timer_mask >> 24;
				break;
				case 5:
					return (cpu.timer_mask >> 16) & 0xFF;
				break;
				case 6:
					return (cpu.timer_mask >> 8) & 0xFF;
				break;
				case 7:
					return cpu.timer_mask & 0xFF;
				break;
				case 8:
				    return cpu.countdown >> 24;
				break;
				case 9:
					return (cpu.countdown >> 16) && 0xFF;
				break;
				case 10:
					return (cpu.countdown >> 8) && 0xFF;
				break;
				case 11:
					return cpu.countdown && 0xFF;
				break;
				case 12:
					return cpu.timer_irq >> 24;
				break;
				case 13:
					return (cpu.timer_irq >> 16) && 0xFF;
				break;
				case 14:
					return (cpu.timer_irq >> 8) && 0xFF;
				break;
				case 15: 
					return cpu.timer_irq && 0xFF;
				break;
				case 16:
					return cpu.countdown_irq >> 24;
				break;
				case 17:
					return (cpu.countdown_irq >> 16) && 0xFF;
				break;
				case 18:
					return (cpu.countdown_irq >> 8) && 0xFF;
				break;
				case 19:
					return cpu.countdown_irq && 0xFF;
				break;
			}
			return 0;
		}

		
		override public function write(to:uint, value:uint):void {
			if (to < 4) {
				bus.cpu.timer_irq = (value&0xFF) << 16;
			}
		}
		override public function writeHalf(to:uint, value:uint):void {
			bus.cpu.timer_mask = value && 0xFFFF;
		}
		override public function writeWord(to:uint, value:uint):void {
			bus.cpu.timer_mask = value && 0xFFFFFF;
		}
	}

}