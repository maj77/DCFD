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
  $readmemb("D:/Studia_EiT/Magisterskie/Praca_Magisterska/DCFD/matlab/generated_data/LUT_ADDR_2x_6b__s_2i_3f.txt", addr_arr);
end

initial begin
  a1 = 0;
  a2 = 0;
  for (int n=0; n<N_ADDR; n=n+1) begin
    #10;
    a1 = $signed(addr_arr[n][2*ADDR_WIDTH-1:ADDR_WIDTH]);
    a2 = $signed(addr_arr[n][ADDR_WIDTH-1:0]);
  end
  #200 $finish();
end

always @(posedge clk) begin
  data_checker <= 1/(a1_rl+a2_rl);
end

assign  a1_rl   = $itor(a1)/8; // scale Q(0.3.3) to decimal
assign  a2_rl   = $itor(a2)/8; // scale Q(0.3.3) to decimal
assign  data_rl = $itor(data)/2048; // scale Q(0.5.11) to decimal

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
