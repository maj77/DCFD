`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 
// Company: AGH
// Engineer: Marcin Maj
// Create Date: 08.09.2024
// Module Name: cfd_axi_tb
// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



import defines_pkg::*;

module cfd_axi_tb();



parameter         C_M00_AXI_START_DATA_VALUE	    = 32'hAA000000;
parameter         C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000;
parameter integer C_M00_AXI_ADDR_WIDTH	            = 32;
parameter integer C_M00_AXI_DATA_WIDTH	            = 32;
parameter integer C_M00_AXI_TRANSACTIONS_NUM	    = 4;
parameter integer C_S00_AXIS_TDATA_WIDTH	        = 32;


logic clk  ;
logic rst_n;

logic [C_S00_AXIS_TDATA_WIDTH-1 : 0] cfd_axi_data_in;
logic                                cfd_data_in_vld;
logic                                cfd_data_in_rdy;
logic [  C_M00_AXI_ADDR_WIDTH-1 : 0] cfd_axi_waddr;
logic                                cfd_axi_aw_vld;
logic [  C_M00_AXI_DATA_WIDTH-1 : 0] cfd_axi_result_data;
logic [C_M00_AXI_DATA_WIDTH/8-1 : 0] cfd_axi_result_strb;
logic                                cfd_axi_result_vld;
logic                                cfd_axi_result_rdy;
logic                                cfd_axi_brdy;

logic [CFD_IN_WIDTH-1:0]     amplitude_8_1408_wave_arr [0:PULSE_SAMPLES-1];
logic [CFD_RESULT_WIDTH-1:0] amplitude_8_1408_result_temp [0:1];
logic [CFD_RESULT_WIDTH-1:0] amplitude_8_1408_result;
logic dummy1, dummy2, dummy3, dummy4; 

initial
    clk  = 1'b0;
always 
    #(CLK_HALF_T) clk  = ~clk;

initial begin
    rst_n = 1'b0;
    #(100*CLK_HALF_T) rst_n = 1'b1;
end

initial begin
    $readmemh("D:/Studia_EiT/Magisterskie/Praca_Magisterska/DCFD/python_scripts/TV/PROCESSED_TV/amplitude_8_1408_.txt", amplitude_8_1408_wave_arr );
    $readmemh("D:/Studia_EiT/Magisterskie/Praca_Magisterska/DCFD/python_scripts/TV/PROCESSED_TV/amplitude_8_1408_result_.txt", amplitude_8_1408_result_temp);   
end

assign amplitude_8_1408_result = amplitude_8_1408_result_temp[0]; // readmemh must have memory as second argument

reg [11:0] testdata = 12'hFFF0;
int sample_no       = 0;
reg   rand_vld_in;

always @(*) begin : testdata_vld
    if (!rst_n) begin
        cfd_data_in_vld = 0;
    end else begin
        // if (cfd_axi_result_vld==1'b0) begin
        if (sample_no < PULSE_SAMPLES) begin
            // cfd_data_in_vld = 1;
            cfd_data_in_vld = rand_vld_in;
        end else begin
            cfd_data_in_vld = 0;
        end
    end
end

// randomize cfd_data_vld_in to check if axi transactions are correctly implemented
always @(posedge clk) begin : randomize_vld_in
    if (!rst_n) begin
        rand_vld_in <= 1'b0;
    end else begin
        rand_vld_in <= $urandom_range(0,1);
    end
end

always @(posedge clk) begin
    if (cfd_data_in_vld && cfd_data_in_rdy) begin
        sample_no = sample_no + 1;
    end
end
assign cfd_axi_data_in = (sample_no==0) ? {19'b0, 1'b1, amplitude_8_1408_wave_arr[sample_no]} 
                                        : {19'b0, 1'b0, amplitude_8_1408_wave_arr[sample_no]};


real cfd_result_real    = -1;
real cfd_zc_result_real = -1;
real matlab_result_real = -1; 
real result_diff        = -1;

initial begin : catch_zc_result
    wait(cfd_axi_uut.cfd_i.zc_result_vld_d==1'b1);
    cfd_zc_result_real = cfd_axi_uut.cfd_i.zc_result;
end
// cfd_axi_result_vld comes always 1clk after zc_result_vld_d
initial begin : result_checker
    cfd_axi_result_rdy = 1'b1;
    
    fork
        begin : wait_for_result_vld
            wait (cfd_axi_result_vld);
            if (cfd_axi_result_vld & cfd_axi_result_rdy) begin
                disable result_failed;
                // [TODO] Matlab result doesnt takie into account all clocks
                //        it contains value of expression  a1/(a1+a2)
                //        rewrite matlab or allign testbench
                //
                // [TODO] Parametrize fxp scaling
                
                cfd_zc_result_real = cfd_zc_result_real/(2**8);
                cfd_result_real = cfd_axi_result_data;
                cfd_result_real = cfd_result_real/(2**8);
                matlab_result_real = amplitude_8_1408_result;
                matlab_result_real = (matlab_result_real/(2**8))/16; // additional div-by-16 because in matlab result was multiplied by 16 - param T=16
                result_diff = matlab_result_real - cfd_zc_result_real;
                $display("\n[INFO] [TEST PASSED] CFD processing finished, total result = %f", cfd_result_real); // result is Q(0.8.8) TODO: CHECK IF THIS FXP FORMAT IS TRUE
                $display("[INFO]                 cfd_zc result     = %f", cfd_zc_result_real);
                $display("[INFO]                 matlab_zc result  = %f", matlab_result_real);
                $display("[INFO]                 result difference = %f\n", result_diff);
                wait(cfd_data_in_vld==1'b0);
                #(15*CLK_HALF_T) $finish;
            end
        end
        begin : result_failed
            wait(rst_n==1'b1);
            @(negedge cfd_data_in_vld); // all samples fed to DUT and no valid occured on output
            $display("\n[INFO] [TEST FAILED] Cfd didn't assert result_vld after processing whole wave");
            // disable wait_for_result_vld;
        end
    join
end



cfd_axi_wrapper #(
    .CFD_IN_WIDTH               (CFD_IN_WIDTH              ),
    .CFD_RESULT_WIDTH           (CFD_RESULT_WIDTH          ), // [TODO] result width is calculated inside cfd module, make this param calculateable (create wrapper which will calculate params and pass them to cfd?)
    .CFD_PIPE_DLY               (CFD_PIPE_DLY              ),
    .CFD_FPGA_CLOCKS_PER_SAMPLE (CFD_FPGA_CLOCKS_PER_SAMPLE),
    .SF_WIDTH                   (CFD_SCALE_FACTOR_WIDTH    )
    // rest of AXI params left default
) cfd_axi_uut (
    //===================================
    // INPUT INTERFACE, AXI STREAM SLAVE
    .s00_axis_aclk        (clk            ), // input
    .s00_axis_aresetn     (rst_n          ), // input
    .s00_axis_tready      (cfd_data_in_rdy), // output
    .s00_axis_tvalid      (cfd_data_in_vld), // input
    .s00_axis_tdata       (cfd_axi_data_in), // input
    .s00_axis_tstrb       (8'hFF          ), // input, whole 32b word is sampled
    //===================================
    // OUTPUT INTERFACE, AXI LITE MASTER     
    .m00_axi_aclk         (clk                ), // input
    .m00_axi_aresetn      (rst_n              ), // input 
    .m00_axi_awaddr       (cfd_axi_waddr      ), // output, set to const inside module
    .m00_axi_awvalid      (cfd_axi_aw_vld     ), // output, addr always vld
    .m00_axi_awready      (1'b1               ), // input
    //-------------used signals---------------
    .m00_axi_wdata        (cfd_axi_result_data), // output
    .m00_axi_wstrb        (cfd_axi_wstrb      ), // output
    .m00_axi_wvalid       (cfd_axi_result_vld ), // output
    .m00_axi_wready       (cfd_axi_result_rdy ), // input    
    //---------end of used signals------------
    .m00_axi_bresp        (2'b00              ), // input, assume no errors while reading from this IF
    .m00_axi_bvalid       (1'b1               ), // input
    .m00_axi_bready       (cfd_axi_brdy       ), // output
    .m00_axi_araddr       (dummy1             ), // output
    .m00_axi_arprot       (dummy2             ), // output
    .m00_axi_arvalid      (dummy3             ), // output
    .m00_axi_arready      (0                  ), // input
    .m00_axi_rdata        (0                  ), // input
    .m00_axi_rresp        (0                  ), // input 
    .m00_axi_rvalid       (0                  ), // input
    .m00_axi_rready       (dummy4             )  // output
);


//-------------- NOT WORKING --------------
// initial begin : feed_samples_into_tb
//     cfd_axi_data_in = 0;
//     cfd_data_in_vld = 1'b0;

//     wait(rst_n == 1'b1);
//     repeat(20) @(posedge clk);
    
//     // generate vld and wait for handshake
//     cfd_axi_data_in = {19'b0, 1'b1,testdata};
//     #(CLK_HALF_T);
//     cfd_data_in_vld = 1'b1;

//     // wait(cfd_data_in_rdy==1'b1); // check if syncd with clock
//     // if (vld & rdy == 1) feed samples, else wait for ready from DUT
//     forever begin
//         if (cfd_data_in_vld & cfd_data_in_rdy) begin // rdy_signal is based on vld
//             //====================
//             // FEED SAMPLES
//             if (sample_no==0) begin
//                 //                {19b unused bits, 1b trigger, 12b adc samples}
//                 // cfd_axi_data_in = {19'b0, 1'b1,amplitude_8_1408_wave_arr[sample_no]};
//                 $display("[DEBUG] Passing first sample which contains trigger bit at %f", $realtime());
//             end else begin
//                 // cfd_axi_data_in = {20'b0, amplitude_8_1408_wave_arr[sample_no]};
//                 cfd_axi_data_in = {20'b0, testdata};
//                 // $display("[DEBUG] Passing sample_no = %d, at %f", sample_no, $realtime());
//             end
//             #(CFD_FPGA_CLOCKS_PER_SAMPLE*2*CLK_HALF_T);
//             //====================
//             // samples control
//             if (sample_no < PULSE_SAMPLES) begin
//                 sample_no = sample_no+1;    
//             end else begin
//                 cfd_axi_data_in = 0;
//                 break;
//             end
//             testdata = testdata + 1'b1;
//         //====================
//         // ready deasserted
//         end else begin
//             wait(cfd_data_in_rdy==1'b1);
//         end
//     end
//     cfd_data_in_vld = 1'b0;
//     #(100*CLK_HALF_T);
//     $finish();
// end

endmodule