`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.09.2023 17:10:10
// Design Name: 
// Module Name: LUT_tb
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////


module LUT_tb();

localparam DATA_WIDTH = 16  ;
localparam ADDR_WIDTH = 6   ;
localparam N_ADDR     = 4096;

logic                           clk                  ;
logic                           rst_p                ;
logic [       2*ADDR_WIDTH-1:0] addr_arr [N_ADDR-1:0];
logic signed [  ADDR_WIDTH-1:0] a1                   ;
logic signed [  ADDR_WIDTH-1:0] a2                   ;
logic signed [  DATA_WIDTH-1:0] data                 ;

//TODO: stworzyc typy REAL i tam przechowywac przeskalowane wartosc a1,a2,data
real a1_rl, a2_rl, data_rl;
real data_checker         ;

initial
  clk = 1'b0;
always
  #5 clk = ~clk;

initial begin
  $readmemb("D:/Studia_EiT/magisterskie/Praca_Magisterska/DCFD/matlab/LUT_ADDR_2x_s_3i_3f.txt", addr_arr);
end

initial begin
  for (int n=0; n<N_ADDR; n=n+1) begin
    #10
    a1 = $signed(addr_arr[n][2*ADDR_WIDTH-1:ADDR_WIDTH]);
    a2 = $signed(addr_arr[n][ADDR_WIDTH-1:0]);
  end
end

always @(posedge clk) begin
  data_checker <= 1/(a1_rl+a2_rl);
end;

assign  a1_rl   = $itor(a1)/8;
assign  a2_rl   = $itor(a2)/8;
assign  data_rl = $itor(data)/2048;

LUT #(
  .ADDR_WIDTH(ADDR_WIDTH),
  .DATA_WIDTH(DATA_WIDTH)
)lut_uut(
  .clk   (clk  ),
  .rst_p (rst_p),
  .a1    (a1   ),
  .a2    (a2   ),
  .data_o(data )
);


endmodule  
