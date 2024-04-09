////////////////////////////////////////////////////////////////////
/// * File Name     :   wbUartTxSlave.v
/// * Author        :   Dai Zisheng
/// * Version       :   V0.1
/// * Description   :   A UART transmitter peripheral based on the wishbone bus
////////////////////////////////////////////////////////////////////

/// ----- Instantiation module example ----- ///
//wbUartTxSlave wbUartTxSlave_inst1(
//    .i_clk          (i_clk),
//    .i_rst          (i_rst),
    
//    .i_wb_cyc       (o_wb_cyc),
//    .i_wb_stb       (o_wb_stb),
//    .i_wb_we        (o_wb_we),
//    .i_wb_addr      (o_wb_addr[31:0]),
//    .i_wb_data      (o_wb_data[31:0]),
    
//    .o_wb_ack       (i_wb_ack),
//    .o_wb_stall     (i_wb_stall),
//    .o_wb_data      (i_wb_data[31:0]),
    
//    .o_uart_txd     (uart_txd),
//    .o_uart_busy    (uart_busy),
//    .o_uart_done    (uart_done)
//); 
/// ------------------ END ----------------- ///

module wbUartTxSlave(
    // SYSCON
    input           i_clk       ,
    input           i_rst       ,
    
    // wishbone inputs
    input           i_wb_cyc    ,   // unused
    input           i_wb_stb    ,
    input           i_wb_we     ,
    input   [31:0]  i_wb_addr   ,
    input   [31:0]  i_wb_data   ,
    
    // wishbone outputs
    output          o_wb_ack    ,
    output          o_wb_stall  ,
    output  [31:0]  o_wb_data   ,
    
    // user port start
    // uartTx Signals
    output          o_uart_txd  ,
    output          o_uart_busy ,
    output          o_uart_done
    // user port end
    );

/// IO    
// Wishbone IO reg
reg reg_wb_oAck;
//reg reg_wb_oStall;                    // comment by DZS 2024-04-06 
reg [31:0]  reg_wb_oData;

// Wishbone connect IO reg to IO wire
assign o_wb_ack = reg_wb_oAck;
//assign o_wb_stall = reg_wb_oStall;    // comment by DZS 2024-04-06 
assign o_wb_stall = o_uart_busy;        // add by DZS 2024-04-06
assign o_wb_data[31:0] = reg_wb_oData[31:0];

/// Wishbone BUS
// Wishbone internal wire
    
// Wishbone internal  reg
reg [31:0] reg_wb_reg0; // status reg£¬0bit£ºtxbusy£¬1'b1 for busy, 1'b0 for not busy,  readonly 
reg [31:0] reg_wb_reg1; // BaudRate£¬default£º115200£¬R/W
reg [31:0] reg_wb_reg2; // [7:0] txdata, Writing this register will trigger a transfer£¬ R/W
reg [31:0] reg_wb_reg3; // not used  R/W   

// Wishbone internal assign connect

/// User logic start
// internal wire
wire wire_uartTxStb;
wire [7:0]  wire_uartTx8bitData;
wire [31:0] wire_uartTxBaud;

// internal reg
reg reg_uartTxStb;

// internal assign connect
assign wire_uartTxStb               = reg_uartTxStb;
assign wire_uartTx8bitData[7:0]     = reg_wb_reg2[7:0];
assign wire_uartTxBaud[31:0]        = reg_wb_reg1[31:0];

/// User logic end

    
/// Wishbone logic
// ack to master
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) begin
        reg_wb_oAck <= 1'b0;
    end else if((i_wb_stb)&&(!o_wb_stall)) begin    // Applicable to pipelined wishbone timing, if it is standard, the ack will have an additional cycle
        reg_wb_oAck <= 1'b1;
    end else begin
        reg_wb_oAck <= 1'b0;
    end
end

// write to slave registers reg1 reg2 reg3
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) begin
//        reg_wb_reg0[31:0] <= 32'h0000_0000;               // comment by DZS 2024-04-06 
        reg_wb_reg1[31:0] <= 32'd115200;
        reg_wb_reg2[31:0] <= 32'h0000_0000;
        reg_wb_reg3[31:0] <= 32'h0000_0000;
    end else if((i_wb_stb)&&(i_wb_we)&&(!o_wb_stall)) begin
        case(i_wb_addr[31:0])
//            32'h0000_0000: begin                          // comment by DZS 2024-04-06
//                reg_wb_reg0[31:0] <= i_wb_data[31:0];     // comment by DZS 2024-04-06 
//            end                                           // comment by DZS 2024-04-06
            32'h0000_0001: begin
                reg_wb_reg1[31:0] <= i_wb_data[31:0];
            end
            32'h0000_0002: begin
                reg_wb_reg2[31:0] <= i_wb_data[31:0];
            end
            32'h0000_0003: begin
                reg_wb_reg3[31:0] <= i_wb_data[31:0];
            end
        endcase
    end
end

// o_wb_data : read from slave registers
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) begin
        reg_wb_oData <= 32'h0000_0000;
    end else if((i_wb_stb)&&(!i_wb_we)&&(!o_wb_stall)) begin
        case(i_wb_addr[31:0])
            32'h0000_0000: begin
                reg_wb_oData[31:0] <= reg_wb_reg0[31:0];
            end
            32'h0000_0001: begin
                reg_wb_oData[31:0] <= reg_wb_reg1[31:0];
            end
            32'h0000_0002: begin
                reg_wb_oData[31:0] <= reg_wb_reg2[31:0];
            end
            32'h0000_0003: begin
                reg_wb_oData[31:0] <= reg_wb_reg3[31:0];
            end
        endcase
    end
end 

/// user logic start

// reg0 status update
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) begin
        reg_wb_reg0[31:0] <= 32'h0000_0000;
    end else begin
        reg_wb_reg0[0] <= o_uart_busy;
    end
end

// reg_uartTxStb
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) begin
        reg_uartTxStb <= 1'b0;
    end else if((i_wb_stb)&&(i_wb_we)&&(!o_wb_stall)) begin
        if((32'h0000_0002 == i_wb_addr[31:0])&&(!o_uart_busy)) begin
            reg_uartTxStb <= 1'b1;   // strobe uart Tx to send
        end
    end else begin
        reg_uartTxStb <= 1'b0;
    end
end

// Instantiate uartByteTx module
uartByteTx #(
    .CLK_HZ(50_000_000)     // HZ         
) uartByteTx_inst1 (
    .i_clk      (i_clk)                         ,
    .i_rst      (i_rst)                         ,
    .i_txData   (wire_uartTx8bitData[7:0])      ,
    .i_txStart  (wire_uartTxStb)                ,
    .i_txBaud   (wire_uartTxBaud[31:0])         ,   // MAX_CLK_HZ: CLK_HZ/2
    .o_txBusy   (o_uart_busy)                   ,
    .o_txDone   (o_uart_done)                   ,
    .o_txd      (o_uart_txd)
);

/// user logic end
    
endmodule
