
`timescale 1 ns / 1 ps

    module cfd_axi_wrapper #(
        // Users to add parameters here
        parameter CFD_IN_WIDTH               = 12 ,
        parameter CFD_PIPE_DLY               = 142,
        parameter CFD_RESULT_WIDTH           = 20 ,
        parameter CFD_FPGA_CLOCKS_PER_SAMPLE = 1  ,
        parameter SF_WIDTH                   = 12 ,
        // User parameters ends
        // Do not modify the parameters beyond this line


        // Parameters of Axi Master Bus Interface M00_AXI
        parameter         C_M00_AXI_START_DATA_VALUE        = 32'hAA000000,
        parameter         C_M00_AXI_TARGET_SLAVE_BASE_ADDR  = 32'h40000000,
        parameter integer C_M00_AXI_ADDR_WIDTH              = 32,
        parameter integer C_M00_AXI_DATA_WIDTH              = 32,
        parameter integer C_M00_AXI_TRANSACTIONS_NUM        = 4,

        // Parameters of Axi Slave Bus Interface S00_AXIS
        parameter integer C_S00_AXIS_TDATA_WIDTH    = 32
    )(
        //====================================================================
        // AXI STREAM SIGNALS
        // Ports of Axi Slave Bus Interface S00_AXIS
        input  wire                                    s00_axis_aclk,    // from tb
        input  wire                                    s00_axis_aresetn, // from tb
        output wire                                    s00_axis_tready,  // logic implemented in axi stream module
        input  wire                                    s00_axis_tvalid,  // will be tie high if FPGA_CLOCKS_PER_SAMPLE=1 or will be 1'b1 for 1 clock in FPGA_CLOCKS_PER_SAMPLE if FPGA_CLOCKS_PER_SAMPLE=16
        input  wire [C_S00_AXIS_TDATA_WIDTH-1 : 0]     s00_axis_tdata,   // input data from testbench
        input  wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,   // will be set to cover [12:0] bits or all bits, doesnt matter

        //====================================================================
        // AXI LITE SIGNALS
        // Ports of Axi Master Bus Interface M00_AXI
        input  wire                                m00_axi_aclk,         // clk from tb
        input  wire                                m00_axi_aresetn,      // reset from tb
        output wire [C_M00_AXI_ADDR_WIDTH-1 : 0]   m00_axi_awaddr,       // const read addr, one reg out of 4, 32bit regs will store result data 
        output wire [2 : 0]                        m00_axi_awprot,       // tielow?
        output wire                                m00_axi_awvalid,      // tiehigh
        input  wire                                m00_axi_awready,      // tiehigh from tb
        output wire [C_M00_AXI_DATA_WIDTH-1 : 0]   m00_axi_wdata,        // here on bits [11:0] will be stored result
        output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,        // whole bus tiehiigh wstrb = 4'b1111;
        output wire                                m00_axi_wvalid,       // will be driven by cfd_result_vld
        input  wire                                m00_axi_wready,       // tiehigh from TB
        input  wire [1 : 0]                        m00_axi_bresp,        // unused
        input  wire                                m00_axi_bvalid,       // unused
        output wire                                m00_axi_bready,       // const or unused
        output wire [C_M00_AXI_ADDR_WIDTH-1 : 0]   m00_axi_araddr,       // const. or module logic
        output wire [2 : 0]                        m00_axi_arprot,       // unused
        output wire                                m00_axi_arvalid,      // tiehigh, from module
        input  wire                                m00_axi_arready,      // tiehigh, from testbench
        input  wire [C_M00_AXI_DATA_WIDTH-1 : 0]   m00_axi_rdata,        // tielow
        input  wire [1 : 0]                        m00_axi_rresp,        // tielow, rresp=00 means no errors
        input  wire                                m00_axi_rvalid,       // tielow from testbench, AXI_LITE is read only, we want to read from it (from module perspective it wants to write sth out)
        output wire                                m00_axi_rready        // rready will be driven by cfd_result_vld
    );

    reg                         cfd_trigger_in;       // enables cfd processing
    wire [        SF_WIDTH-1:0] scale_factor  ;       // will remain hardcoded
    reg  [    CFD_IN_WIDTH-1:0] cfd_data_in   ;       // input data samples
    wire                        cfd_result_vld;       // signal indicating that zero-cross occured
    wire [CFD_RESULT_WIDTH-1:0] cfd_result    ;
    wire                        unused_net;

    //====================================================================
    // AXI LITE MODULE
    cfd_axi_lite_master_if # ( 
        .C_M_START_DATA_VALUE      (C_M00_AXI_START_DATA_VALUE      ),
        .C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
        .C_M_AXI_ADDR_WIDTH        (C_M00_AXI_ADDR_WIDTH            ),
        .C_M_AXI_DATA_WIDTH        (C_M00_AXI_DATA_WIDTH            ),
        .C_M_TRANSACTIONS_NUM      (C_M00_AXI_TRANSACTIONS_NUM      ),
        .CFD_RESULT_WIDTH          (CFD_RESULT_WIDTH                )
    ) i_cfd_axi_lite_master_if (
        .M_AXI_ACLK    (m00_axi_aclk        ),
        .M_AXI_ARESETN (m00_axi_aresetn     ),
        .M_AXI_AWADDR  (m00_axi_awaddr      ),
        .M_AXI_AWPROT  (m00_axi_awprot      ),
        .M_AXI_AWVALID (m00_axi_awvalid     ),
        .M_AXI_AWREADY (m00_axi_awready     ),
        .M_AXI_WDATA   (m00_axi_wdata       ),
        .M_AXI_WSTRB   (m00_axi_wstrb       ),
        .M_AXI_WVALID  (m00_axi_wvalid      ),
        .M_AXI_WREADY  (m00_axi_wready      ),
        .M_AXI_BRESP   (m00_axi_bresp       ),
        .M_AXI_BVALID  (m00_axi_bvalid      ),
        .M_AXI_BREADY  (m00_axi_bready      ),
        .M_AXI_ARADDR  (m00_axi_araddr      ),
        .M_AXI_ARPROT  (m00_axi_arprot      ),
        .M_AXI_ARVALID (m00_axi_arvalid     ),
        .M_AXI_ARREADY (m00_axi_arready     ),
        .M_AXI_RDATA   (m00_axi_rdata       ),
        .M_AXI_RRESP   (m00_axi_rresp       ),
        .M_AXI_RVALID  (m00_axi_rvalid      ),
        .M_AXI_RREADY  (m00_axi_rready      ),
        .CFD_DATA_VLD  (cfd_result_vld      ),
        .CFD_RESULT    (cfd_result          )
    );

//====================================================================
// AXI STREAM MODULE
    cfd_axi_stream_slave_if # ( 
        .C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
    ) i_cfd_axi_stream_slave_if (
        .S_AXIS_ACLK    (s00_axis_aclk   ),
        .S_AXIS_ARESETN (s00_axis_aresetn),
        .S_AXIS_TREADY  (s00_axis_tready ),
        .S_AXIS_TDATA   (s00_axis_tdata  ),
        .S_AXIS_TSTRB   (s00_axis_tstrb  ),
        .S_AXIS_TLAST   (s00_axis_tlast  ),
        .S_AXIS_TVALID  (s00_axis_tvalid ),
        .FIFO_DATA_RDY  (CFD_DATA_RDY    ),
        .FIFO_DATA_VLD  (fifo_data_vld   ),
        .FIFO_DATA_OUT  (cfd_data_in     ),
        .CFD_TRIGGER    (cfd_trigger_in  )
    );


    assign scale_factor = 12'b1100_1100_1101; // 0.8
    // assign scale_factor = 12'b0011_0011_0011; // 0.2

    cfd #( .IN_WIDTH              (CFD_IN_WIDTH              ),
           .OUT_WIDTH             (CFD_RESULT_WIDTH          ),
           .PIPE_DLY              (CFD_PIPE_DLY              ),
           .FPGA_CLOCKS_PER_SAMPLE(CFD_FPGA_CLOCKS_PER_SAMPLE)
    )cfd_i(
           .clk                   (s00_axis_aclk    ),
           .rst_p                 (~s00_axis_aresetn),
           .sf                    (scale_factor     ),
           .sample_in             (cfd_data_in      ),
           .trigger               (cfd_trigger_in   ),
           .cfd_rdy               (CFD_DATA_RDY     ),
           .axi_data_vld          (fifo_data_vld    ),
           .pulse_out             (cfd_result_vld   ),
           .data_out              (cfd_result       ),
           .th_passthrough_in     (1'b0             ),
           .th_passthrough_out_vld(unused_net       )
    );

    endmodule
