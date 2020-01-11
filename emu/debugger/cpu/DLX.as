package emu.debugger.cpu 
{
	import com.memory.StringManip;
	import emu.hardware.cpu.CPU;
	/**
	 * ...
	 * @author Elliott Smith [voidSkipper]
	 */
	public class DLX
	{
		public static const oplabelshighbranch:Array = 
									[["add", bin("100000"), "rk,ri,rj"],
									["addu", bin("100001"), "rk,ri,rj"],
									["and", bin("100100"), "rk,ri,rj"],
									["halt", bin("000001"), ""],
									["movi2s", bin("110000"), ""],
									["movs2i", bin("110001"), ""],
									["nop", bin("000000"), ""],
									["or", bin("100101"), "rk,ri,rj"],
									["seq", bin("101000"), "rk,ri,rj"],
									["sequ", bin("010000"), "rk,ri,rj"],
									["sge", bin("101101"), "rk,ri,rj"],
									["sgeu", bin("010101"), "rk,ri,rj"],
									["sgt", bin("101011"), "rk,ri,rj"],
									["sgtu", bin("010011"), "rk,ri,rj"],
									["sla", bin("000100"), "rk,ri,rj"],
									["sle", bin("101100"), "rk,ri,rj"],
									["sleu", bin("010100"), "rk,ri,rj"],
									["sll", bin("000100"), "rk,ri,rj"],
									["slt", bin("101010"), "rk,ri,rj"],
									["sltu", bin("010010"), "rk,ri,rj"],
									["sne", bin("101001"), "rk,ri,rj"],
									["sneu", bin("010001"), "rk,ri,rj"],
									["sra", bin("000111"), "rk,ri,rj"],
									["srl", bin("000110"), "rk,ri,rj"],
									["sub", bin("100010"), "rk,ri,rj"],
									["subu", bin("100011"), "rk,ri,rj"],
									["wait", bin("000010"), ""],
									["xor", bin("100110")], "rk,ri,rj"];
									
		public static const oplabels0x:Array = 
									[["addi", bin("001000"), "rj,ri,ksgn"],
									["addui", bin("001001"), "rj,ri,kuns"],
									["andi", bin("001100"), "rj,ri,kuns"],
									["beqz", bin("000100"), "ri,ksgn"],
									["bnez", bin("000101"), "ri,ksgn"],
									["j", bin("000010"), "lsgn"],
									["jal", bin("000011"), "lsgn"],
									["jalr", bin("010011"), "ri"],
									["jr", bin("010010"), "ri"],
									["lb", bin("100000"), "rj,ksgn(ri)"],
									["lbu", bin("100100"), "rj,ksgn(ri)"],
									["lh", bin("100001"), "rj,ksgn(ri)"],
									["lhi", bin("001111"), "rj,kuns"],
									["lhu", bin("100101"), "rj,ksgn(ri)"],
									["lw", bin("100011"), "rj,ksgn(ri)"],
									["ori", bin("001101"), "rj,ri,kuns"],
									["rfe", bin("010000"), ""],
									["sb", bin("101000"), "ksgn(ri),rj"],
									["seqi", bin("011000"), "rj,ri,ksgn"],
									["sequi", bin("110000"), "rj,ri,kuns"],
									["sgei", bin("011101"), "rj,ri,ksgn"],
									["sgeui", bin("110101"), "rj,ri,kuns"],
									["sgti", bin("011011"), "rj,ri,ksgn"],
									["sgtui", bin("110011"), "rj,ri,kuns"],
									["sh", bin("101001"), "ksgn(ri),rj"],
									["slai", bin("010100"), "rj,ri,kuns"],
									["slei", bin("011100"), "rj,ri,ksgn"],
									["sleui", bin("110100"), "rj,ri,kuns"],
									["slli", bin("010100"), "rj,ri,kuns"],
									["slti", bin("011010"), "rj,ri,ksgn"],
									["sltui", bin("110010"), "rj,ri,kuns"],
									["snei", bin("011001"), "rj,ri,ksgn"],
									["sneui", bin("110001"), "rj,ri,kuns"],
									["srai", bin("010111"), "rj,ri,kuns"],
									["srli", bin("010110"), "rj,ri,kuns"],
									["subi", bin("001010"), "rj,ri,ksgn"],
									["subui", bin("001011"), "rj,ri,kuns"],
									["sw", bin("101011"), "ksgn(ri),rj"],
									["trap", bin("010001"), "luns"],
									["xori", bin("001110"), "rj,ri,kuns"]];
									
		
		public function DLX(cpu:CPU) 
		{
		
		}
		
		public static function getCPUStatus(cpu:CPU):String {
			var s:String = "CPU STATUS\n-------------------\n"
			s = s + "PC: 0x" + StringManip.pad(cpu.PC.toString(16)) + " ";
			s = s + "IR: 0x" + StringManip.pad(cpu.IR.toString(16), "0", 8, true) + " ";
			
			s = s + "(" + StringManip.pad(cpu.IR.toString(2), "0", 32, true, true, 8) + ")\n";
			
			s = s + "TIMA: " + (cpu.getTick() & cpu.timer_mask) + " (Mask: " + cpu.timer_mask.toString(16) + " Ticks: " + cpu.getTick() + ")\n";
			var IR:uint = cpu.IR;
			var opcode:uint = (IR >> 26) & 0x3F;
			var args:uint = IR & 0x3FFFFFF;
			var a_i:uint = (args >> 21) & 0x1F;
			var a_j:uint = (args >> 16) & 0x1F;
			var a_k:uint = (args >> 11) & 0x1F;
			var a_m:uint = args & 0x3F;
			var a_Kuns:uint = args & 0xFFFF;
			var a_Ksgn:int = a_Kuns;
			var a_Luns:uint = args;
			var a_Lsgn:int = a_Luns;
			if ((a_Kuns & 0x8000) != 0) {
				a_Ksgn = -a_Ksgn;
			}
			if ((a_Luns & 0x2000000) != 0) {
				a_Lsgn = -a_Lsgn;
			}
			var i:uint = 0;
			//trace(opcode.toString(2), a_m.toString(2));
			var oplbl:Array = ["Undefined Opcode", 0, ""];
			if (opcode) {
				while (i < oplabels0x.length) {
					//trace(oplabels0x[i][1], opcode);
					//trace("non-alu", opcode, oplabels0x[i]);
					if(oplabels0x[i][1]==opcode){
						s = s + "\n" + oplabels0x[i][0];
						oplbl = oplabels0x[i];
						break;
					}
					i++;
				}
			}
			else {
				while (i < oplabelshighbranch.length) {
					//trace(oplabelshighbranch[i][1], a_m);
					//trace("alu", opcode, oplabelshighbranch[i]);
					if(oplabelshighbranch[i][1]==a_m){
						s=s+"\n"+oplabelshighbranch[i][0];
						oplbl = oplabelshighbranch[i];
						break;
					}
					i++;
				}
			}
			
			var als:Array = String(oplbl[2]).split(",");
			var append:String = "";
			if (als.length > 0) {
				append = "    ";
				i = 0;
				while (i < als.length) {
					if (als[i] == "ri") {
						append = append + "r" + a_i;
					}
					else if (als[i] == "rj") {
						append = append + "r" + a_j;
					}
					else if (als[i] == "rk") {
						append = append + "r" + a_k;
					}
					else if (als[i] == "kuns") {
						append = append + "0x" + a_Kuns.toString(16);
					}
					else if (als[i] == "ksgn") {
						append = append + "0x" + a_Ksgn.toString(16);
					}
					else if (als[i] == "ksgn(ri)") {
						append = append + "0x" + a_Kuns.toString(16)+"(r"+a_i+")";
					}
					else if (als[i] == "luns") {
						append = append + "0x" + a_Luns.toString(16);
					}
					else if (als[i] == "lsgn") {
						append = append + "0x" + a_Lsgn.toString(16);
					}
					i++
					if (i < als.length) {
						append = append + ",";
					}
				}
			}
			
			s = s+append+"\n";
			i = 0;
			while (i < cpu.r.length) {
				if (!(i % 4)&&i) {
					s = s + "\n";
				}
				s = s + "r" + StringManip.pad(i.toString(), "0", 2) + ": 0x" + StringManip.pad(uint(cpu.r[i]).toString(16)) + " ";
				i++;
			}
			s = s + "\n\n";
			s = s + "PSW: (" + StringManip.pad(cpu.sr[cpu.PSW].toString(2), "0", 32, true, true, 8) + ") XBR: 0x" + StringManip.pad(cpu.sr[cpu.XBR].toString(16));
			s = s + "\nIRQ: (" + StringManip.pad(cpu.IRQQueue.toString(2), "0", 32, true, true, 8) + ") XAR: 0x" + StringManip.pad(cpu.sr[cpu.XAR].toString(16));
			return s;
		}
		
		private static function bin(input:String):uint {
			return parseInt(input, 2);
		}
	}

}