// ���ߣ� ��¶��
// ����: ��ˮ������������
// �汾: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module ctrl(

	input wire										rst,
    input wire                      stop_inst,
	input wire                   stallreq_from_id,

  //����ִ�н׶ε���ͣ����
	input wire                   stallreq_from_ex,
	input wire                   stallreq_from_dcache,
	input wire                   stallreq_from_icache,
	output reg[5:0]              stall       
	
);


	always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
		end else if(stallreq_from_icache == `Stop) begin
			stall <= 6'b111111;				
		end else if(stallreq_from_dcache == `Stop)begin
			stall <= 6'b111111;
		end else if(stallreq_from_ex == `Stop) begin
			stall <= 6'b001111;
		end else if(stallreq_from_id == `Stop) begin
			stall <= 6'b000111;			
		end else if(stop_inst == `Stop) begin
			stall <= 6'b000111;			
		end else begin
			stall <= 6'b000000;
		end    //if
	end      //always
			

endmodule