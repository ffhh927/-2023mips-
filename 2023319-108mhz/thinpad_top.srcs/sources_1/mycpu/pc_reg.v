// ���ߣ� ��¶��
// ����: ָ��ָ��Ĵ���PC
// �汾: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module pc_reg(

	input	wire										clk,
	input wire										rst,
	input wire [5:0]                            stall,//��ͣ�ź�
	

	
	input wire                    branch_flag_i,//�Ƿ���ת��
	input wire[`RegBus]           branch_target_address_i,//ת�Ƶ��ĵ�ַ
	
	output reg[`InstAddrBus]			pc,//ȡ��ָ��ĵ�ַ
	output reg                    ce  //ָ��Ĵ�ʹ���ź�
	
);
// ָ���ַ����

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;
		end else begin
            if(stall[0]==`NoStop) begin
                if(branch_flag_i == `Branch) begin
                    pc <= branch_target_address_i;
                end else begin
                    pc <= pc + 4'h4;
                end 
            end else begin
                 pc <= pc;
            end 
		end 
	end
// ����ָ��	
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule