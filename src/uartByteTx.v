////////////////////////////////////////////////////////////////////
/// * File Name     :   uartByteTx.v
/// * Author        :   Dai Zisheng
/// * Version       :   V0.1
/// * Description   :   8bit data 1bit stop bit uart sending module
////////////////////////////////////////////////////////////////////

/// ----- Instantiation module example ----- ///
//uartByteTx #(
//    .CLK_HZ(50_000_000)
//) uartBytx_inst1(
//    .i_clk      (clk),
//    .i_rst      (rst),
//    .i_txData   (txData[7:0),
//    .i_txStart  (txStart),
//    .i_txBaud   (txBaud),
    
//    .o_txBusy   (txBusy),
//    .o_txDone   (txDone),
//    .o_txd      (TXD)
//) 
/// ------------------ END ----------------- ///

module uartByteTx #(
    parameter integer CLK_HZ = 50_000_000
)(
    // input wire
    input         i_clk     ,
    input         i_rst     ,
    input [7:0]   i_txData  ,
    input         i_txStart ,                 
    input [31:0]  i_txBaud  ,
    
    // output wire
    output        o_txBusy  ,
    output        o_txDone  ,
    output        o_txd
    );

// IO reg
reg reg_oTxBusy;
reg reg_oTxDone;
reg reg_oTxd;

// connect IO reg to IO wire
assign o_txBusy = reg_oTxBusy;
assign o_txDone = reg_oTxDone;
assign o_txd = reg_oTxd;
    
// internal wire
wire        wire_txDoSample;
wire [31:0] wire_baudDiv;

// internal reg
reg [10:0] reg_txShifter;   // Bit definition: flag_stopbit_B7_B6_B5_B4_B3_B2_B1_B0_startbit    (Send lowest bit first)
reg [31:0] reg_txCntr;

// internal assign connect
assign wire_txDoSample = (reg_txCntr[31:0] == 0);
assign wire_baudDiv = CLK_HZ / i_txBaud;

// Down counter generates baud rate
always@(posedge i_clk or posedge i_rst)begin
    if( (i_rst) || (reg_txCntr[31:0] == 0) ) begin
        reg_txCntr[31:0] <= (wire_baudDiv-1'b1);
    end else begin
        reg_txCntr[31:0] <= reg_txCntr[31:0] - 1'b1;
    end
end

// o_txBusy
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) begin
        reg_oTxBusy <= 1'b0;
    end else if((!o_txBusy)&&(i_txStart)) begin         // The tx transmission start signal is detected when in idle state
        reg_oTxBusy <= 1'b1;
    end else if((o_txBusy)&&(wire_txDoSample)&&(~|reg_txShifter[10:1])) begin   // Condition: in busy state; next bit pulse arrives; and all bits are sent.
        reg_oTxBusy <= 1'b0;
    end
end

// o_txDone
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) begin
        reg_oTxDone <= 1'b0;
    end else if((o_txBusy)&&(wire_txDoSample)&&(~|reg_txShifter[10:1])) begin   // Condition: in busy state; next bit pulse arrives; and all bits are sent.
        reg_oTxDone <= 1'b1;
    end else begin
        reg_oTxDone <= 1'b0;
    end
end

// reg_txShifter o_txd
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) begin
        reg_txShifter[10:0] <= 0;
        reg_oTxd <= 1'b1;
    end else if((!o_txBusy)&&(i_txStart)) begin                     // The tx transmission start signal is detected when in idle state
        reg_txShifter[10:0] <= { 1'b1,1'b1,i_txData[7:0],1'b0 };    // Initialize transmit shift register
        end else if((o_txBusy)&&(wire_txDoSample)) begin            // Condition: in busy state; next bit pulse arrives;
        { reg_txShifter[10:0],reg_oTxd } <= ({ reg_txShifter[10:0],reg_oTxd } >> 1);  // On each baud rate clock arrival, the shift register shifts
    end
end

endmodule
