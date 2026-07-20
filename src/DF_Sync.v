
// ************************* Description *********************** //
//  This synchronizer is implemented to:-                        //
//   -- synchronize data bus encoded in gray code                //
//   -- synchronize control bus encoded in gray code             //
//   -- synchronize address bus encoded in gray code             //
// ************************************************************* //

module DF_Sync #(
  parameter DATA_SIZE = 2                         // data width
)
  (
    input                           sync_clk ,
    input                           sync_rstn ,
    input       [DATA_SIZE-1:0]     unsync_ip ,
    output  reg [DATA_SIZE-1:0]     sync_op
  ) ;


reg [DATA_SIZE-1:0]  meta_flop ;


always @ (posedge sync_clk or negedge sync_rstn)
 begin
  if(!sync_rstn)
   begin
    meta_flop   <= 0 ;
    sync_op  <= 0 ;
   end
 else
  begin
    meta_flop  <= unsync_ip ;
    sync_op  <= meta_flop ;
  end
 end



endmodule
