// ���ߣ� ��¶��
// ����: ָ���icache
// �汾: 1.0
//////////////////////////////////////////////////////////////////////
`define ZeroWord 32'h00000000

module icache(
    //ʱ��
    input wire clk,
    input wire rst,
//��cpu����
        //if�׶��������Ϣ�ͻ�õ�ָ��
    (* DONT_TOUCH = "1" *) input    wire[31:0]  rom_addr_i,        //��ȡָ��ĵ�ַ
    (* DONT_TOUCH = "1" *) input    wire        rom_ce_i,          //ָ��洢��ʹ���ź�
     output   reg [31:0]  inst_o,            //��ȡ����ָ��

    output   reg         stall,
//��sram����������
     input wire  inst_stop,
     input   wire [31:0]  inst_i          //��ȡ����ָ��

);


//icache��Ҫʵ�ֵĹ��ܰ�����
//��ȡ
//����ʱȡָ
//δ����ʱ������ˮ����ͣ�źţ���sram��ȡֵ


//cache��С32*32����1K=128B
//����ֱ��ӳ�䣬ÿ��ֻһ���֣�����Ѱַ2λ,cache��ַ5λ
//basesram��С4MB����ַ22λ
//tag 22-5-2=15λ
//valid 1λ
parameter Cache_Num = 32;
parameter Tag = 15;
parameter Cache_Index = 5;
parameter Block_Offset = 2;
 reg[31:0] cache_mem[0:Cache_Num-1];//cache memory
 reg[Tag-1:0] cache_tag[0:Cache_Num-1];//cache tag
 reg[Cache_Num-1:0]        cache_valid;//cache valid

//״̬��
parameter IDLE=0;//��̬
parameter READ_SRAM=1;

reg[1:0] state,next_state;

always@(posedge clk or posedge rst)begin
    if(rst)begin
        state<=IDLE;
      //  state<= READ_SRAM;
    end else begin
        state<=next_state;
    end
end


//read
//hit(����ָ�����У�д����û������)
wire [Tag-1:0] ram_tag_i = rom_addr_i[21:7];//ram tag
wire [Cache_Index-1:0] ram_cache_i = rom_addr_i[6:2];//ram cache block addr

wire hit = (state==IDLE)?cache_valid[ram_cache_i]&&(cache_tag[ram_cache_i]==ram_tag_i):1'b0;//tag��ͬ��valid=1���У�д��Ч��
//wire hit =1'b0;
reg finish_read;
integer i;
//��ȡָ��
always@(*)begin
    if(rst)begin
        finish_read = 1'b0;
        inst_o = `ZeroWord;       //��ȡ��ָ��
    end else begin
        case(state)
        IDLE:begin
            finish_read = 1'b0;       
            if(hit&&~inst_stop)begin
                inst_o = cache_mem[ram_cache_i];
            end else begin
                inst_o = `ZeroWord;
            end
        end
        READ_SRAM: begin       
                inst_o = inst_i;       //��ȡ��ָ��  
                finish_read = 1'b1;   
        end
        default:begin 
            finish_read = 1'b0;
            inst_o = 32'hzzzzzzzz;
        end
        endcase
    end
end
//����cache memory
wire rst_n = ~rst;
always@(posedge clk or posedge rst_n)begin
    if(!rst_n)begin
        for(i=0 ; i < 32 ; i=i+1)begin
                cache_mem[i] <= 32'b0;
                cache_tag[i] <= 15'b0;
            end  
        cache_valid <=32'h00000000;
    end else begin
        case(state)
        READ_SRAM: begin       
                cache_mem[ram_cache_i] <= inst_i;
                cache_valid[ram_cache_i] <= 1'b1;
                cache_tag[ram_cache_i] <= ram_tag_i;//cache tag  
        end
        default:begin 
                 cache_mem[ram_cache_i] <= cache_mem[ram_cache_i];
                cache_valid[ram_cache_i] <= cache_valid[ram_cache_i];
                cache_tag[ram_cache_i] <= cache_tag[ram_cache_i];//cache tag  
        end
        endcase
    end
end
//״̬����
always@(*)begin
    if(rst)begin
        stall = 1'b0;     
        next_state = READ_SRAM;
    end else begin
        case(state)
            IDLE:begin
                if(rom_ce_i&&~hit&&~inst_stop)begin//����δ����
                    next_state=READ_SRAM;
                    stall = 1'b1;
                end else begin
                    next_state=IDLE;
                    stall = 1'b0;
                end
            end
            READ_SRAM:begin
                if(finish_read)begin
                    next_state=IDLE;
                    stall = 1'b0;
                    end
                else begin
                    next_state=READ_SRAM;
                    stall = 1'b1;  
                    stall = 1'b0;
                end 
             end
            default:begin 
                     next_state = IDLE;
                     stall = 1'b0;
            end
        endcase
    end
end
endmodule