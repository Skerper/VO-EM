package emu.hardware.memory 
{
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class ROM extends BA_RAM
	{
		private var localdata:ByteArray;
		private var mirrorWord:Vector.<uint>;
		private var mirrorHalf:Vector.<uint>;
		private var locked:Boolean = false;
		public function ROM(location:uint = 0x0, size:uint = 0xFFFF) 
		{
			super(location, size);
			mirrorWord = new Vector.<uint>()
			mirrorWord.length = size;
			mirrorWord.fixed = true;
			mirrorHalf = new Vector.<uint>()
			mirrorHalf.length = size;
			mirrorHalf.fixed = true;
			this.size = size;
		}
		
		public function lock():void {
			
			//dump(0x200, 0, 10);
			var i:uint = 0;
			var c:uint = 0;
			while (i < size) {
				//trace(readWord(i));
				mirrorWord[i] = data[i] << 24 | data[i + 1] << 16 | data[i + 2] << 8 | data[i + 3];
				mirrorHalf[i] = data[i] << 24 | data[i + 1] << 16;;
				mirrorHalf[i + 2] = data[i + 2] << 8 | data[i + 3];
				i+=4;
			}
			//trace(mirrorWord, mirrorHalf);
			localdata = new ByteArray();
			data.position = 0;
			data.readBytes(localdata);
			locked = true;
		}
		
		override public function readWord(from:uint):uint {
			return mirrorWord[from];
		}
		
		override public function readHalf(from:uint):uint {
			return mirrorHalf[from];
		}
		
		override public function read(from:uint):uint {
			return localdata[from];
		}
		
		override public function write(to:uint, value:uint):void {
			if (!locked) {	
				super.write(to, value);
			}
			else {
				trace("Write attempted to ROM - target:0x" + to.toString(16) + ", value:0x" + value.toString(16));
			}
		}
		
		
		override public function writeWord(to:uint, value:uint):void {
			if (!locked) {
				super.writeWord(to, value);
			}
			else {
				trace("Write attempted to ROM - target:0x" + to.toString(16) + ", value:0x" + value.toString(16));
			}
		}
	}

}