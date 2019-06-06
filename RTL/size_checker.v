//==================================================================================================
// -----------------------------------------------------------------------------
// Copyright (c) 2018 All rights reserved
// -----------------------------------------------------------------------------
//  Filename      : size_checker.v
//  Author        : Mario Daniel Ruiz Noguera
//  Company       : HPCN-UAM
//  Email         : mario.ruiz@uam.es
//  Created On    : 2018-04-05 15:56:08
//  Last Modified : 2018-09-04 12:44:07
//
//  Revision      : 1.0
//
//  Description   : This Module completes the packet to 60 bytes when the packets are smaller than 60 bytes
//==================================================================================================
`timescale 1ns/1ps

module size_checker#
    (
        // Width of S_AXI data bus
        parameter C_AXIS_DATA_WIDTH             = 512,
        parameter TUSER_WIDTH                   =  1,
        parameter TDEST_WIDTH                   =  1

    )
    (
      (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK CLK" *)
      (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS:M_AXIS, ASSOCIATED_RESET RST_N" *)
      input  wire                      CLK            ,
      (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST_N RST" *)
      (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
      input  wire                      RST_N          ,
    
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)  
      input  wire              [511:0] S_AXIS_TDATA   ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TKEEP" *)
      input  wire               [63:0] S_AXIS_TSTRB   ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TLAST" *) 
      input  wire                      S_AXIS_TLAST   ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *) 
      input  wire                      S_AXIS_TVALID  ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDEST" *) 
      input  wire  [TDEST_WIDTH-1 : 0] S_AXIS_TDEST   ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TUSER" *) 
      input  wire  [TUSER_WIDTH-1 : 0] S_AXIS_TUSER   ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *) 
      output wire                      S_AXIS_TREADY  ,

      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)   
      output reg               [511:0] M_AXIS_TDATA   ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TKEEP" *)
      output reg                [63:0] M_AXIS_TSTRB   ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TLAST" *)
      output reg                       M_AXIS_TLAST   ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
      output reg                       M_AXIS_TVALID  ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDEST" *) 
      output reg   [TDEST_WIDTH-1 : 0] M_AXIS_TDEST   ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TUSER" *)
      output reg   [TUSER_WIDTH-1 : 0] M_AXIS_TUSER   ,
      (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
      input  wire                      M_AXIS_TREADY 

);

  reg     first_transaction= 1'b1;

  assign  S_AXIS_TREADY = M_AXIS_TREADY;

  always @(*) begin
    M_AXIS_TDATA      <= S_AXIS_TDATA;    
    M_AXIS_TSTRB      <= S_AXIS_TSTRB;    
    M_AXIS_TLAST      <= S_AXIS_TLAST;    
    M_AXIS_TVALID     <= S_AXIS_TVALID;    
    M_AXIS_TDEST      <= S_AXIS_TDEST;    
    M_AXIS_TUSER      <= S_AXIS_TUSER;          

    if (S_AXIS_TVALID && S_AXIS_TREADY && S_AXIS_TLAST) begin         // one-transaction packet
      if (first_transaction && ~S_AXIS_TSTRB[60]) begin
        M_AXIS_TSTRB    <= {4'd0,{60{1'b1}}};                         // complete packet to the minimum size (60 bytes)
      end
    end
  end


  always @(posedge CLK) begin
    if (~RST_N) begin
      first_transaction   <= 1'b1;
    end
    else begin
      if (S_AXIS_TVALID && S_AXIS_TREADY) begin                         // when a valid transaction is active tie low flag
        first_transaction   <= 1'b0;
      end

      if (S_AXIS_TVALID && S_AXIS_TREADY && S_AXIS_TLAST) begin         // one-transaction packet
        first_transaction <= 1'b1;                                      // Asserting flag with the last transaction of a packet (it could be one-transaction packet)
      end
    end
  end

endmodule