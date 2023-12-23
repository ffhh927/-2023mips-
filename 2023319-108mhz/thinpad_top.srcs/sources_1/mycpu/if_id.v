// ���ߣ� ��¶��
// ����: IF/ID�׶εļĴ���
// �汾: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module if_id(

	input	wire										clk,
	input wire										rst,
	input wire[5:0]                            stall,//��ͣ�ź�

	input wire[`InstAddrBus]			if_pc,
	input wire[`InstBus]          if_inst,
	output reg[`InstAddrBus]      id_pc,
	output reg[`InstBus]          id_inst  
	
);
//��if_pc��if_inst�ݴ棬id_pc��id_inst���´���
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
	    end else begin
	       if(stall[1]==`Stop&&stall[2]==`NoStop) begin
	           id_pc <= `ZeroWord;
			   id_inst <= `ZeroWord;
	       end else  if(stall[1]==`NoStop) begin
		       id_pc <= if_pc;
		       id_inst <= if_inst;
		   end else begin
		       id_pc <= id_pc;
		       id_inst <= id_inst;
		   end
	   end
	end

endmodule