`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.03.2024 13:13:26
// Design Name: 
// Module Name: cfd_behav_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cfd_behav_tb();


localparam PIPE_DLY      = 80;
localparam SCALE_FACTOR  = 0.8;
localparam PULSE_SAMPLES = 2201; // chek this value in matlab
localparam CLK_HALF_T    = 5;


logic clk                             ;
logic rst_p                           ;
real  in_pulse_arr [PULSE_SAMPLES-1:0];
real  data_in                         ;
logic pulse_out                       ;
logic sample_in_vld                   ;

integer fd; // fil;e handle
string data;

//initial begin
//  $readmem("D:/Studia_EiT/magisterskie/Praca_Magisterska/DCFD/CFD_rtl/CFD/gaussian_pulse_double.txt", in_pulse_arr);
//end


// TODO: NIE DZIALA ODCZYTYWANIE WARTOSCI Z PLIKU
integer i;
initial begin
  fd = $fopen("D:/Studia_EiT/magisterskie/Praca_Magisterska/DCFD/CFD_rtl/CFD/gaussian_pulse_double2.txt", "r");
  i = 0;
  while(!$feof(fd)) begin
    $fgets(data, fd);
    $display("data: %e", data);
    in_pulse_arr[i] = data.atoreal();
    $display("pulse_arr: %e", in_pulse_arr[i]);
    i = i+1;
    
  end
  $fclose(fd);
  //$finish();
end

initial
  clk = 1'b0;
always
  #CLK_HALF_T clk = ~clk;
  
initial begin
  rst_p = 1'b1;
  #20 rst_p = 1'b0;
end

initial begin
  data_in = '{default:0};
  @(negedge rst_p);
  @(posedge clk); // allign to rising edges of clock
  
  // feed one sample to CFD every 16 clocks
  // sample is valid only for one CFD period
  for(int n=0; n<PULSE_SAMPLES; n=n+1) begin
    data_in = in_pulse_arr[n];
    sample_in_vld = 1'b1;
    #(2*CLK_HALF_T); 
    sample_in_vld = 1'b0;
    #(15*2*CLK_HALF_T);
  end
  #(100*CLK_HALF_T) $finish();
end

cfd_behav #( 
       .PIPE_DLY    (PIPE_DLY    ),
       .SCALE_FACTOR(SCALE_FACTOR)
)cfd_uut(
       .clk          (clk          ),
       .rst_p        (rst_p        ),
       .sample_in_vld(sample_in_vld),
       .sample_in    (data_in      ),
       .pulse_out    (pulse_out    )
    );
endmodule
