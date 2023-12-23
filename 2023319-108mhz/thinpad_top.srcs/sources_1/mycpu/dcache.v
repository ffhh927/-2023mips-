// ���ߣ� ��¶��
// ����: ���ݻ���dcache
// �汾: 1.0
//////////////////////////////////////////////////////////////////////
`define ZeroWord 32'h00000000

module dcache(
    //ʱ��
    input wire clk,
    input wire rst,
//��cpu����
//mem�׶δ��ݵ���Ϣ��ȡ�õ�����
    output   reg[31:0]   ram_data_o,        //��ȡ������
    input    wire[31:0]  mem_addr_i,        //����д����ַ
    input    wire[31:0]  mem_data_i,        //д�������
    input    wire        mem_we_n_i,          //дʹ�ܣ�����Ч
    input    wire[3:0]   mem_sel_n_i,         //�ֽ�ѡ���ź�
    input    wire        mem_ce_i,          //Ƭѡ�ź�

    input    wire        inst_stop,
    
    output   reg         stall,
//��sram����������
    input     wire[31:0] ram_data_i        //��ȡ������

);
//dcache��Ҫʵ�ֵĹ��ܰ�����
//��ȡ
//����ʱȡָ
//δ����ʱ������ˮ����ͣ�źţ���sram��ȡֵ
//д��(дֱ�
//дcacheͬʱ��sramд


//cache��С32*32����1K=128B
//����ֱ��ӳ�䣬ÿ��ֻһ���֣�����Ѱַ2λ,cache��ַ5λ
//basesram��С4MB����ַ22λ
//tag 23-5-2=16λ
//valid 1λ
parameter Cache_Num = 32;
parameter Tag = 16;
parameter Cache_Index = 5;
parameter Block_Offset = 2;
 reg[31:0] cache_mem[0:Cache_Num-1];//cache memory
 reg[Tag-1:0] cache_tag[0:Cache_Num-1];//cache tag
 reg[3:0]     cache_valid[Cache_Num-1:0] ;//cache valid
 //reg[Cache_Num-1:0]        cache_dirty;//

//״̬��
parameter IDLE=0;//��̬
parameter READ_SRAM=1;
parameter WRITE_SRAM=2;

reg[1:0] state,next_state;

always@(posedge clk,posedge rst)begin
    if(rst)begin
        state<=IDLE;
    end else begin
        state<=next_state;
    end
end
//������
wire uart_req = (mem_ce_i & ((mem_addr_i == 32'hbfd003f8)|(mem_addr_i == 32'hbfd003fc)))?1'b1:1'b0;

//read
//hit(����ָ�����У�д����û������)
wire [Tag-1:0] ram_tag_i = mem_addr_i[22:7];//ram tag
wire [Cache_Index-1:0]  ram_cache_i = mem_addr_i[6:2];//ram cache block addr


//wire hit =(mem_we_n_i)&&(state==IDLE)?(cache_valid[ram_cache_i]==~mem_sel_n_i)&&(cache_tag[ram_cache_i]==ram_tag_i)&&mem_ce_i:1'b0;//tag��ͬ��valid=1���У�д��Ч��
wire hit = 1'b0;
//wire[31:0] data = cache_mem[ram_cache_i];
//writebuffer
reg[31:0]cache_wb;
reg cache_wb_vaild;


//
//reg sram_ready;
//wire wr_en;
//wire[63:0] wb_data;
//wire[63:0]dout;
//wire rd_en = sram_ready;
//wire full;
//wire empty;

//fifo_generator_0 writebuffer (
//  .clk(clk),      // input wire clk
//  .srst(rst),    // input wire srst
//  .din(wb_data),      // input wire [63 : 0] din
//  .wr_en(wr_en),  // input wire wr_en
//  .rd_en(rd_en),  // input wire rd_en
//  .dout(dout),    // output wire [63 : 0] dout
//  .full(full),    // output wire full
//  .empty(empty)  // output wire empty
//);



//reg[31:0]  mem_addr_i_r;       //����д����ַ
//reg[31:0]  mem_data_i_r;        //д�������
//reg mem_we_n_i_r;          //дʹ�ܣ�����Ч
//reg[3:0]   mem_sel_n_i_r;         //�ֽ�ѡ���ź�
//reg        mem_ce_i_r;          //Ƭѡ�ź�
//reg [Tag-1:0] ram_tag_i_r;
//reg [Cache_Index-1:0]  ram_cache_i_r;

reg finish_read;
reg finish_write;

integer i;
reg[63:0] wb_data_r;
always@(*)begin
    if(rst)begin
        for(i=0 ; i < 32 ; i=i+1)begin
                    cache_mem[i] = 32'b0;
                    cache_tag[i] = 16'b0;
                    cache_valid[i] = 4'b0;
                end  
        finish_read = 1'b0;
        finish_write = 1'b0;
        ram_data_o = `ZeroWord;       //��ȡ������
    end else begin
        case(state)
        IDLE:begin
            finish_read = 1'b0;
            finish_write = 1'b0;
            //�����cache
            if(hit&&!uart_req)begin
                ram_data_o = cache_mem[ram_cache_i];
            end else if(uart_req)begin
                ram_data_o = ram_data_i;                
            end else begin
                ram_data_o = 32'b0;
            end
            //����дcache
            
        end
        READ_SRAM: begin      
            //��sram 
            ram_data_o = ram_data_i;       //��ȡ������ 
            finish_read = 1'b1;         
            //д��cache
 //           if(!uart_req)begin         
            cache_mem[ram_cache_i] = ram_data_i;
            cache_valid[ram_cache_i] = ~mem_sel_n_i;
            cache_tag[ram_cache_i] = ram_tag_i;//cache tag
  //          end else begin end
        end
        WRITE_SRAM:begin    
            //дSRAM
            ram_data_o = 32'b0;           
            finish_write = 1'b1;   
            //дcache
   //         if(!uart_req)begin
                if(cache_valid[ram_cache_i]!=~mem_sel_n_i&&cache_valid[ram_cache_i]!=4'b0)begin
                case(mem_sel_n_i)
                    4'b0000:begin 
                        cache_mem[ram_cache_i] =  mem_data_i;
                        cache_valid[ram_cache_i] = 4'b1111;
                     end
                    4'b1110:begin
                        cache_mem[ram_cache_i][7:0] = mem_data_i[7:0];
                        cache_valid[ram_cache_i][0] = 1'b1;
                    end
                    4'b1101:begin
                        cache_mem[ram_cache_i][15:8] = mem_data_i[15:8];
                        cache_valid[ram_cache_i][1] = 1'b1;
                    end
                    4'b1011:begin
                        cache_mem[ram_cache_i][23:16] = mem_data_i[23:16];
                        cache_valid[ram_cache_i][2] = 1'b1;
                    end
                    4'b0111:begin
                        cache_mem[ram_cache_i][31:24] = mem_data_i[31:24];
                        cache_valid[ram_cache_i][3] = 1'b1;
                    end
                   default:begin
                        cache_mem[ram_cache_i] = mem_data_i;
                        cache_valid[ram_cache_i][0] = 4'b0000;
                   end
                 endcase
             end else begin
                    cache_mem[ram_cache_i] = mem_data_i;
                    cache_valid[ram_cache_i] = ~mem_sel_n_i;
             end
                 cache_tag[ram_cache_i] = ram_tag_i;//cache tag
   //         end else begin end
            
        end
        default:begin end
        endcase
    end
end

always@(*)begin
    if(rst)begin
        stall = 1'b0;
        next_state=IDLE;
    end else begin
        case(state)
            IDLE:begin
                if(mem_we_n_i&&(hit!=1'b1)&&mem_ce_i&&!uart_req)begin//����δ����
                    next_state=READ_SRAM;
                    stall = 1'b1;
                end else if(~mem_we_n_i&&mem_ce_i&&!uart_req) begin//д
                    next_state=WRITE_SRAM;
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
                 end 
             end
            WRITE_SRAM:begin
                if(finish_write)begin
                    next_state=IDLE;
                    stall = 1'b0;
                    end
                else begin
                    next_state=WRITE_SRAM;
                end
             end
            default:next_state=IDLE;
        endcase
    end
end
endmodule