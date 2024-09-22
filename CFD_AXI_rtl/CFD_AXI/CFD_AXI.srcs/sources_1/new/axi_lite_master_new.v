`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  AGH
// Engineer: Marcin Maj
// 
// Create Date        : 07.09.2024 21:37:00
// Design Name        : cfd_axi_lite_master_if
// Project Name       : Constant Fraction Discriminator
// Tool Versions      : vivado >2018.3
// Additional Comments: Interface based on auto generated axi-lite-master interface,
//                      READ part of interface remains unused, left for xilinx tools compliance
//////////////////////////////////////////////////////////////////////////////////

module cfd_axi_lite_master_if #(
    parameter integer CFD_RESULT_WIDTH           = 20,
    parameter         C_M_START_DATA_VALUE       = 32'hAA000000, // The master will start generating data from the C_M_START_DATA_VALUE value
    parameter         C_M_TARGET_SLAVE_BASE_ADDR = 32'h40000000, // The master requires a target slave base address. The master will initiate read and write transactions on the slave with base address specified here as a parameter.
    parameter integer C_M_AXI_ADDR_WIDTH         = 32,           // Width of M_AXI address bus. The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
    parameter integer C_M_AXI_DATA_WIDTH         = 32,           // Width of M_AXI data bus. The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
    parameter integer C_M_TRANSACTIONS_NUM       = 4             // Transaction number is the number of write and read transactions the master will perform as a part of this example memory test.
)(
    //==========================================================
    // CFD CONNECTION
    //==========================================================
    input wire                               CFD_DATA_VLD,
    input wire [       CFD_RESULT_WIDTH-1:0] CFD_RESULT  ,
    //==========================================================
    // CLOCKS, ETC
    //==========================================================
    input  wire                              INIT_AXI_TXN,
    input  wire                              M_AXI_ACLK,
    input  wire                              M_AXI_ARESETN,
    //==========================================================
    // MASTER WRITE INTERFACE
    //==========================================================
    output wire [  C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,  // Master Interface Write Address Channel ports. Write address (issued by master)
    output wire [                     2 : 0] M_AXI_AWPROT,  // This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
    output wire                              M_AXI_AWVALID, // This signal indicates that the master signaling valid write address and control information.
    input  wire                              M_AXI_AWREADY, // This signal indicates that the slave is ready to accept an address and associated control signals.
    output wire [  C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,   // Master Interface Write Data Channel ports. Write data (issued by master)
    output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,   // This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
    output wire                              M_AXI_WVALID,  // Write valid. This signal indicates that valid write data and strobes are available.
    input  wire                              M_AXI_WREADY,  // Write ready. This signal indicates that the slave can accept the write data.
    //==========================================================
    // Master Interface Write Response Channel ports. 
    //==========================================================
    // This signal indicates the status of the write transaction.
    input  wire [                     1 : 0] M_AXI_BRESP,
    input  wire                              M_AXI_BVALID,
    output wire                              M_AXI_BREADY,
    //==========================================================
    // MASTER READ INTERFACE - not implemented
    //==========================================================
    output wire [  C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output wire [                     2 : 0] M_AXI_ARPROT,
    output wire                              M_AXI_ARVALID,
    input  wire                              M_AXI_ARREADY,
    input  wire [  C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input  wire [                     1 : 0] M_AXI_RRESP,
    input  wire                              M_AXI_RVALID,
    output wire                              M_AXI_RREADY
);

// function called clogb2 that returns an integer which has the
// value of the ceiling of the log base 2

function integer clogb2 (input integer bit_depth);
    begin
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
        bit_depth = bit_depth >> 1;
    end
endfunction

// TRANS_NUM_BITS is the width of the index counter for 
// number of write or read transaction.
localparam integer TRANS_NUM_BITS = clogb2(C_M_TRANSACTIONS_NUM-1);

// AXI4LITE signals
reg                            axi_awvalid;       //write address valid
reg                            axi_wvalid;        //write data valid
reg                            axi_bready;        //write response acceptance
reg [C_M_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;        //write address
reg [C_M_AXI_DATA_WIDTH-1 : 0] axi_wdata;         //write data
wire                           write_resp_error;  //Asserts when there is a write response error
reg [  CFD_RESULT_WIDTH-1 : 0] cfd_result_r;

// I/O Connections assignments
assign M_AXI_AWADDR  = C_M_TARGET_SLAVE_BASE_ADDR + axi_awaddr; //Adding the offset address to the base addr of the slave
assign M_AXI_WDATA   = axi_wdata;    //AXI 4 write data
assign M_AXI_AWPROT  = 3'b000;
assign M_AXI_AWVALID = axi_awvalid;
assign M_AXI_WVALID  = axi_wvalid;   //Write Data(W)
assign M_AXI_WSTRB   = 4'b1111;      //Set all byte strobes in this example
assign M_AXI_BREADY  = axi_bready;   //Write Response (B)
    
// unused read interface signals
assign M_AXI_ARADDR  = C_M_TARGET_SLAVE_BASE_ADDR;
assign M_AXI_ARVALID = 1'b0;
assign M_AXI_ARPROT  = 3'b001;
assign M_AXI_RREADY  = 1'b0;


always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 0) begin
        cfd_result_r <= 0;
    end else begin    
        cfd_result_r <= CFD_RESULT; // reg for future
    end
end

//--------------------
//Write Data Channel
//--------------------
always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 0) begin
        axi_wvalid <= 1'b0;
    end else if (CFD_DATA_VLD) begin //[WARNING] in case if data needs additional reg, this needs to be also delayed by 1clk
        axi_wvalid <= 1'b1;
    end else if (M_AXI_WREADY && axi_wvalid) begin
        axi_wvalid <= 1'b0;
    end
end

//Write Addresses
always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 0) begin
        axi_awaddr <= 0;
    end else if (M_AXI_AWREADY && axi_awvalid) begin
        axi_awaddr <= 32'h00000004; // [INFO] always write to the same addr
    end
end

// Write data
always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 0) begin
        axi_wdata <= 0;
    end else if (M_AXI_WREADY && CFD_DATA_VLD) begin // CFD_DATA_VLD is asserted 1clk before axi_wvalid
        axi_wdata <= CFD_RESULT;                     // [WARNING] watch out for timing issue
    end
end
    
//---------------------
//Write Address Channel
//---------------------
// write address is constant
always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 0) begin
        axi_awvalid <= 1'b0;
    end else begin
        axi_awvalid <= 1'b1;
    end
end

//----------------------------
//Write Response (B) Channel
//----------------------------
always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 0) begin
        axi_bready <= 1'b0;
    end else if (M_AXI_BVALID && ~axi_bready) begin // accept/acknowledge bresp with axi_bready by the master when M_AXI_BVALID is asserted by slave
        axi_bready <= 1'b1;
    end else if (axi_bready) begin // deassert after one clock cycle
        axi_bready <= 1'b0;
    end else begin // retain the previous value
        axi_bready <= axi_bready;
    end
end

//Flag write errors
assign write_resp_error = (axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]);

endmodule