// ���ߣ� ��¶��
// ����: sram�������ʹ��ڿ�����
// �汾: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

`define SerialState 32'hBFD003FC    //����״̬��ַ
`define SerialData  32'hBFD003F8    //�������ݵ�ַ

module SRAM_UART_ctrl (
    input wire clk,
    input wire rst,

    //if�׶��������Ϣ�ͻ�õ�ָ��
    (* DONT_TOUCH = "1" *) input    wire[31:0]  rom_addr_i,        //��ȡָ��ĵ�ַ
    (* DONT_TOUCH = "1" *) input    wire        rom_ce_i,          //ָ��洢��ʹ���ź�
     output   reg [31:0]  inst_o,            //��ȡ����ָ��

    //mem�׶δ��ݵ���Ϣ��ȡ�õ�����
    output   reg[31:0]   ram_data_o,        //��ȡ������
    input    wire[31:0]  mem_addr_i,        //����д����ַ
    input    wire[31:0]  mem_data_i,        //д�������
    input    wire        mem_we_n,          //дʹ�ܣ�����Ч
    input    wire[3:0]   mem_sel_n,         //�ֽ�ѡ���ź�
    input    wire        mem_ce_i,          //Ƭѡ�ź�

    //BaseRAM�ź�
    inout    wire[31:0]  base_ram_data,     //BaseRAM����
    output   reg [19:0]  base_ram_addr,     //BaseRAM��ַ
    output   reg [3:0]   base_ram_be_n,     //BaseRAM�ֽ�ʹ�ܣ�����Ч��
    output   reg         base_ram_ce_n,     //BaseRAMƬѡ������Ч
    output   reg         base_ram_oe_n,     //BaseRAM��ʹ�ܣ�����Ч
    output   reg         base_ram_we_n,     //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout    wire[31:0]  ext_ram_data,      //ExtRAM����
    output   reg [19:0]  ext_ram_addr,      //ExtRAM��ַ
    output   reg [3:0]   ext_ram_be_n,      //ExtRAM�ֽ�ʹ�ܣ�����Ч��
    output   reg         ext_ram_ce_n,      //ExtRAMƬѡ������Ч
    output   reg         ext_ram_oe_n,      //ExtRAM��ʹ�ܣ�����Ч
    output   reg         ext_ram_we_n,      //ExtRAMдʹ�ܣ�����Ч
    
    output   reg         stop_inst, 

    //ֱ�������ź�
    output   wire        txd,                //ֱ�����ڷ��Ͷ�
    input    wire        rxd                //ֱ�����ڽ��ն�

);

wire [7:0]  RxD_data;           //���յ�������
reg [7:0]  TxD_data;           //�����͵�����
wire        RxD_data_ready;     //�������յ��������֮����Ϊ1
wire        TxD_busy;           //������״̬�Ƿ�æµ��1Ϊæµ��0Ϊ��æµ
reg        TxD_start;          //�������Ƿ���Է������ݣ�1������Է���
reg        RxD_clear;          //Ϊ1ʱ��������ձ�־��ready�źţ�


//�ڴ�ӳ��
wire is_SerialState = (mem_addr_i ==  `SerialState); 
wire is_SerialData  = (mem_addr_i == `SerialData);
wire is_base_ram    = (mem_addr_i >= 32'h80000000) 
                    && (mem_addr_i < 32'h80400000);
wire is_ext_ram     = (mem_addr_i >= 32'h80400000)
                    && (mem_addr_i < 32'h80800000);
                    
wire [1:0]state;

reg [31:0] serial_o;        //�����������
wire[31:0] base_ram_o;      //baseram�������
wire[31:0] ext_ram_o;       //extram�������


//����ʵ����ģ�飬������9600
async_receiver #(.ClkFrequency(108000000),.Baud(9600))   //����ģ��
                ext_uart_r(
                   .clk(clk),                           //�ⲿʱ���ź�
                   .RxD(rxd),                           //�ⲿ�����ź�����
                   .RxD_data_ready(RxD_data_ready),     //���ݽ��յ���־
                   .RxD_clear(RxD_clear),               //������ձ�־
                   .RxD_data(RxD_data)                  //���յ���һ�ֽ�����
                );

async_transmitter #(.ClkFrequency(108000000),.Baud(9600)) //����ģ��
                    ext_uart_t(
                      .clk(clk),                        //�ⲿʱ���ź�
                      .TxD(txd),                        //�����ź����
                      .TxD_busy(TxD_busy),              //������æ״ָ̬ʾ
                      .TxD_start(TxD_start),            //��ʼ�����ź�
                      .TxD_data(TxD_data)               //�����͵�����
                    );
//�����շ�
wire rst_n = ~rst;
always @(*) begin

        TxD_start = 1'b0;
        serial_o = 32'h0000_0000;
        TxD_data = 8'h00;
        
        if(is_SerialState) begin                                     //���´���״̬
            serial_o = {{30{1'b0}}, {RxD_data_ready, !TxD_busy}};
            TxD_start = 1'b0;
            TxD_data = 8'h00;
        end
        else if(is_SerialData) begin                  
            if(mem_we_n) begin                             //������    
                serial_o = {24'h000000, RxD_data};
                TxD_start = 1'b0;
                TxD_data = 8'h00;
            end
            else if(!TxD_busy)begin                          //������
                TxD_data = mem_data_i[7:0];
                TxD_start = 1'b1;
                serial_o = 32'h0000_0000;
            end else begin
                TxD_start = 1'b0;
                serial_o = 32'h0000_0000;
                TxD_data = 8'h00;
             end
        end
        else begin
            TxD_start = 1'b0;
            serial_o = 32'h0000_0000;
            TxD_data = 8'h00;
        end
end
//������
always @(*) begin
        RxD_clear = 1'b1;
        if(RxD_data_ready&&is_SerialData&&mem_we_n) begin
            RxD_clear = 1'b1;
        end
        else begin
            RxD_clear = 1'b0;
        end
end

//����BaseRam��ָ��洢����
assign base_ram_data = is_base_ram ? ((mem_we_n == 1'b0) ? mem_data_i : 32'hzzzzzzzz) : 32'hzzzzzzzz;
assign base_ram_o = base_ram_data;      //��ȡ����BaseRam����

//��mem�׶���Ҫ��BaseRam�ĵ�ַд����ȡ����ʱ�������ṹð��
always @(*) begin
    base_ram_addr = 20'h00000;
    base_ram_be_n = 4'b1111;
    base_ram_ce_n = 1'b1;
    base_ram_oe_n = 1'b1;
    base_ram_we_n = 1'b1;
    inst_o = `ZeroWord;
    stop_inst = 1'b0;//basesram����ռ��
    if(is_base_ram) begin           //�漰��BaseRam��������ݲ�������Ҫ��ͣ��ˮ��
        base_ram_addr = mem_addr_i[21:2];   //�ж���Ҫ�󣬵���λ��ȥ
        base_ram_be_n = mem_sel_n;
        base_ram_ce_n = 1'b0;
        base_ram_oe_n = !mem_we_n;
        base_ram_we_n = mem_we_n;
        inst_o = `ZeroWord;
        stop_inst = 1'b1;
    end else begin                  //���漰��BaseRam��������ݲ���������ȡָ��
        base_ram_addr = rom_addr_i[21:2];   //�ж���Ҫ�󣬵���λ��ȥ
        base_ram_be_n = 4'b0000;
        base_ram_ce_n = 1'b0;
        base_ram_oe_n = 1'b0;
        base_ram_we_n = 1'b1;
       
        if(is_SerialData)begin  //���ں�ȡָ���ͬʱ
        stop_inst = 1'b1;
        inst_o = `ZeroWord;
        end else begin
        stop_inst = 1'b0;
        inst_o = base_ram_o;
        end
    end
end


//����ExtRam�����ݴ洢����
assign ext_ram_data = is_ext_ram ? ((mem_we_n == 1'b0) ? mem_data_i : 32'hzzzzzzzz) : 32'hzzzzzzzz;
assign ext_ram_o = ext_ram_data;

always @(*) begin
    ext_ram_addr = 20'h00000;
    ext_ram_be_n = 4'b1111;
    ext_ram_ce_n = 1'b1;
    ext_ram_oe_n = 1'b1;
    ext_ram_we_n = 1'b1;
    if(is_ext_ram) begin           //�漰��extRam��������ݲ���
        ext_ram_addr = mem_addr_i[21:2];    //�ж���Ҫ�󣬵���λ��ȥ
        ext_ram_be_n = mem_sel_n;
        ext_ram_ce_n = 1'b0;
        ext_ram_oe_n = !mem_we_n;
        ext_ram_we_n = mem_we_n;
    end else begin
        ext_ram_addr = 20'h00000;
        ext_ram_be_n = 4'b1111;
        ext_ram_ce_n = 1'b1;
        ext_ram_oe_n = 1'b1;
        ext_ram_we_n = 1'b1;
    end
end


//ȷ�����������

always @(*) begin
    ram_data_o = `ZeroWord;
     if(is_SerialState || is_SerialData ) begin
         ram_data_o = serial_o;         
     end else
     if (is_base_ram) begin
        ram_data_o = base_ram_o;       
    end else if (is_ext_ram) begin
        ram_data_o = ext_ram_o;     
    end else begin
        ram_data_o = `ZeroWord;     
    end
end


endmodule //ram