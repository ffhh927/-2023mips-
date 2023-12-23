// ���ߣ���¶��
// ����: ִ�н׶�
// �汾: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module ex(

	input wire										rst,
	
	//�͵�ִ�н׶ε���Ϣ
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,

    //�ӳٲ�
    input wire[`RegBus]           link_address_i,
	input wire                    is_in_delayslot_i,	
	//ls,ָ��
	input wire[`RegBus]           inst_i,
	
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg[`RegBus]						wdata_o,
	//�ô�
	output wire[`AluOpBus]        aluop_o,//�ô�����
	output wire[`RegBus]          mem_addr_o,//�ô��ַ
	output wire[`RegBus]          reg2_o,//�ô�����
	
	output reg										stallreq 
);
    //����aluop_i
	reg[`RegBus] logicout;//�����߼�����Ľ��
	reg[`RegBus] shiftres;//������λ������
	
	reg[`RegBus] moveres;
	reg[`RegBus] arithmeticres;
	reg[`DoubleRegBus] mulres;	
	reg[`RegBus] HI;
	reg[`RegBus] LO;
	wire[`RegBus] reg2_i_mux;
	wire[`RegBus] reg1_i_not;	
	wire[`RegBus] result_sum;
	wire ov_sum;
	wire reg1_eq_reg2;
	wire reg1_lt_reg2;
	wire[`RegBus] opdata1_mult;
	wire[`RegBus] opdata2_mult;
	wire[`DoubleRegBus] hilo_temp;	
	

//����
    assign reg2_i_mux = (aluop_i == `EXE_SUB_OP) 
											 ? (~reg2_i)+1 : reg2_i;
	assign result_sum = reg1_i + reg2_i_mux;										 

	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
									((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));  

  
    assign reg1_i_not = ~reg1_i;
	
	//�ô�
     assign aluop_o = aluop_i;
     assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
     assign reg2_o = reg2_i;
	
	//�߼�����
	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OR_OP:			begin
					logicout <= reg1_i | reg2_i;
				end
				`EXE_AND_OP:		begin
					logicout <= reg1_i & reg2_i;
				end
				`EXE_XOR_OP:		begin
					logicout <= reg1_i ^ reg2_i;
				end
				default:				begin
					logicout <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always
	
	//��λ����
	always @ (*) begin
		if(rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_SLL_OP:			begin
					shiftres <= reg2_i << reg1_i[4:0] ;
				end
				`EXE_SRL_OP:		begin
					shiftres <= reg2_i >> reg1_i[4:0];
				end
				`EXE_SRA_OP:		begin
					shiftres <= ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) 
												| reg2_i >> reg1_i[4:0];
				end
				default:				begin
					shiftres <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always
	
	//��������
    always @ (*) begin
            if(rst == `RstEnable) begin
                arithmeticres <= `ZeroWord;
            end else begin
                case (aluop_i)
                    `EXE_ADDU_OP, `EXE_ADDIU_OP :		begin
                        arithmeticres <= result_sum; 
                    end
                    `EXE_SUB_OP:		begin
					arithmeticres <= result_sum; 
			     	end		
			     	
                    default:				begin
					arithmeticres <= `ZeroWord;
				end
			endcase
		end
	end
	//�˷�����
	assign opdata1_mult = ((aluop_i == `EXE_MUL_OP) && (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;

  assign opdata2_mult = ((aluop_i == `EXE_MUL_OP) && (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;		

  assign hilo_temp = opdata1_mult * opdata2_mult;																				

	always @ (*) begin
		if(rst == `RstEnable) begin
			mulres <= {`ZeroWord,`ZeroWord};
		end else if (aluop_i == `EXE_MUL_OP)begin
			if(reg1_i[31] ^ reg2_i[31] == 1'b1) begin
				mulres <= ~hilo_temp + 1;
			end else begin
			  mulres <= hilo_temp;
			end
		end else begin
				mulres <= hilo_temp;
		end
	end



    //����alusel_i
     always @ (*) begin
         wd_o <= wd_i;	 	 	
         if( (aluop_i == `EXE_SUB_OP)&& (ov_sum == 1'b1)) begin
	 	     wreg_o <= `WriteDisable;
	     end else begin
	         wreg_o <= wreg_i;
	    end
         stallreq <= `NoStop;
         case ( alusel_i ) 
            `EXE_RES_LOGIC:		begin
                wdata_o <= logicout;
            end
            `EXE_RES_SHIFT:		begin
	 		wdata_o <= shiftres;
	    	end	
            `EXE_RES_ARITHMETIC:	begin
	 		wdata_o <= arithmeticres;
	 	     end
	 	     `EXE_RES_MUL:		begin
	 		wdata_o <= mulres[31:0];
	       	end	 
	 	     `EXE_RES_JUMP_BRANCH:	begin
	 		wdata_o <= link_address_i;
	 	     end	
            default:					begin
                wdata_o <= `ZeroWord;
            end
         endcase
    end	

endmodule