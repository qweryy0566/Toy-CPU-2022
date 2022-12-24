`include "config.v"
`include "IF.v"
`include "LSB.v"
`include "ICache.v"
`include "Issue.v"
`include "RegFile.v"
`include "ROB.v"
`include "RS.v"
`include "FU.v"
`include "MemCtrl.v"

`ifndef __CPU__
`define __CPU__

// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full

  output wire                 L_rob_next_full,
  output wire                 L_rs_next_full,
  output wire                 L_lsb_next_full,
  output wire                 L_exc_valid,
  output wire                 L_jump_flag,
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
  wire                  jump_flag;
  wire                  update_pred_valid;
  wire [`PRED_RANGE]    update_pred_index;
  wire                  update_pred_need_jump;

  wire                  ic_to_mem_valid;
  wire [31:0]           ic_to_mem_addr;
  wire                  mem_to_ic_valid;
  wire [31:0]           mem_to_ic_inst;
  wire [31:0]           if_to_ic_pc;
  wire                  ic_to_if_valid;
  wire [31:0]           ic_to_if_inst;
  wire                  if_to_issue_valid;
  wire [4:0]            if_to_reg_rs1;
  wire [4:0]            if_to_reg_rs2;
  wire [31:0]           rob_to_if_pc;

  wire                  lsb_to_mem_valid;
  wire [31:0]           lsb_to_mem_addr;
  wire [31:0]           lsb_to_mem_store_data;
  wire [2:0]            lsb_to_mem_size;
  wire                  lsb_to_mem_wr_tag;
  wire                  mem_to_lsb_valid;
  wire [31:0]           mem_to_lsb_load_data;

  wire [`ROB_LOG - 1:0] issue_send_RobId;
  wire                  rob_to_issue_rs1_ready;
  wire [31:0]           rob_to_issue_rs1_value;
  wire                  rob_to_issue_rs2_ready;
  wire [31:0]           rob_to_issue_rs2_value;
  wire [31:0]           reg_to_issue_Vj;
  wire [31:0]           reg_to_issue_Vk;
  wire                  reg_to_issue_Rj;
  wire                  reg_to_issue_Rk;
  wire [`ROB_LOG - 1:0] reg_to_issue_Qj;
  wire [`ROB_LOG - 1:0] reg_to_issue_Qk;
  wire                  issue_to_rob_valid;
  wire                  issue_to_rob_pred;
  wire                  issue_to_reg_valid;
  wire                  issue_to_rs_valid;
  wire [`OP_LOG - 1:0]  issue_op;
  wire [4:0]            issue_rd;
  wire [31:0]           issue_Vj; 
  wire [31:0]           issue_Vk;
  wire                  issue_Rj;
  wire                  issue_Rk;
  wire [`ROB_LOG - 1:0] issue_Qj;
  wire [`ROB_LOG - 1:0] issue_Qk;
  wire [31:0]           issue_Imm;
  wire [31:0]           issue_CurPc;
  wire                  issue_to_lsb_valid;

  wire                  rs_to_fu_valid;
  wire [`OP_LOG - 1:0]  rs_to_fu_op;
  wire [31:0]           rs_to_fu_Vj;
  wire [31:0]           rs_to_fu_Vk;
  wire [31:0]           rs_to_fu_Imm;
  wire [`ROB_LOG - 1:0] rs_to_fu_DestRob;
  wire [31:0]           rs_to_fu_CurPc;
  wire                  fu_broadcast_valid;
  wire [31:0]           fu_broadcast_value;
  wire [`ROB_LOG - 1:0] fu_broadcast_RobId;
  wire [31:0]           fu_broadcast_toPC;

  wire                  rob_to_reg_valid;
  wire [4:0]            rob_to_reg_dest;
  wire [31:0]           rob_to_reg_value;
  wire [`ROB_LOG - 1:0] rob_to_reg_RobId;
  //wire                  

  wire                  rob_to_lsb_valid;
  wire [`ROB_LOG - 1:0] rob_to_lsb_RobId;
  wire                  lsb_broadcast_valid;
  wire [`ROB_LOG - 1:0] lsb_broadcast_RobId;
  wire [31:0]           lsb_broadcast_value;
  wire                  lsb_to_rob_store_valid;
  wire [`ROB_LOG - 1:0] lsb_to_rob_store_RobId;

  wire [`ROB_LOG - 1:0] rob_top_id;
  wire [`ROB_LOG - 1:0] rob_next;
  wire                  rob_next_full;
  wire                  rs_next_full;
  wire                  lsb_next_full;

  // personal use
  assign L_rob_next_full = rob_next_full;
  assign L_rs_next_full = rs_next_full;
  assign L_lsb_next_full = lsb_next_full;
  assign L_exc_valid = fu_broadcast_valid;
  assign L_jump_flag = jump_flag;

  MemCtrl u_MemCtrl(
  	.clk            (clk_in         ),
    .rst            (rst_in         ),
    .rdy            (rdy_in         ),
    .mem_din        (mem_din        ),
    .mem_dout       (mem_dout       ),
    .mem_a          (mem_a          ),
    .mem_wr         (mem_wr         ),
    .io_buffer_full (io_buffer_full ),
    .ic_valid       (ic_to_mem_valid),
    .addr_from_ic   (ic_to_mem_addr ),
    .ic_enable      (mem_to_ic_valid),
    .inst_to_ic     (mem_to_ic_inst ),
    .lsb_valid      (lsb_to_mem_valid),
    .lsb_addr       (lsb_to_mem_addr),
    .lsb_store_data (lsb_to_mem_store_data),
    .lsb_size       (lsb_to_mem_size),
    .lsb_wr_tag     (lsb_to_mem_wr_tag),
    .lsb_enable     (mem_to_lsb_valid),
    .lsb_load_data  (mem_to_lsb_load_data)
  );

  ICache icache(
    .clk           (clk_in),
    .rst           (rst_in),
    .rdy           (rdy_in),
    .pc_from_if    (if_to_ic_pc),
    .inst_enable   (ic_to_if_valid),
    .inst_to_if    (ic_to_if_inst),
    .addr_enable   (ic_to_mem_valid),
    .addr_to_mem   (ic_to_mem_addr),
    .mem_valid     (mem_to_ic_valid),
    .inst_from_mem (mem_to_ic_inst)
  );

  InstFetch u_InstFetch(
  	.clk              (clk_in           ),
    .rst              (rst_in           ),
    .rdy              (rdy_in           ),
    .pc_to_ic         (if_to_ic_pc),
    .inst_get_ready   (ic_to_if_valid),
    .inst_from_ic     (ic_to_if_inst),
    .inst_send_enable (if_to_issue_valid),
    .op_type_to_issue (issue_op),
    .rd_to_issue      (issue_rd),
    .rs1_to_reg       (if_to_reg_rs1),
    .rs2_to_reg       (if_to_reg_rs2),
    .imm_to_issue     (issue_Imm),
    .pc_to_issue      (issue_CurPc),
    .pred_to_issue    (issue_to_rob_pred),
    .jump_flag        (jump_flag        ),
    .target_pc        (rob_to_if_pc),
    .rob_next_full    (rob_next_full),
    .rs_next_full     (rs_next_full),
    .lsb_next_full    (lsb_next_full),
    .upd_pred_valid   (update_pred_valid),
    .upd_pred_index    (update_pred_index),
    .upd_pred_need_jump(update_pred_need_jump)
  );

  FU u_FU(
    .rst        (rst_in),
    .rdy        (rdy_in),
  	.RS_valid   (rs_to_fu_valid),
    .RS_op      (rs_to_fu_op),
    .RS_Vj      (rs_to_fu_Vj),
    .RS_Vk      (rs_to_fu_Vk),
    .RS_Imm     (rs_to_fu_Imm),
    .RS_DestRob (rs_to_fu_DestRob),
    .RS_CurPC   (rs_to_fu_CurPc),
    .B_enable   (fu_broadcast_valid),
    .B_value    (fu_broadcast_value),
    .B_RobId    (fu_broadcast_RobId),
    .B_toPC     (fu_broadcast_toPC)
  );

  Issue u_Issue(
    .rst             (rst_in),
    .rdy             (rdy_in),
    .inst_valid      (if_to_issue_valid),
    .op_type_from_if (issue_op),
    .exc_valid      (fu_broadcast_valid),
    .exc_value      (fu_broadcast_value),
    .exc_RobId      (fu_broadcast_RobId),
    .LSB_valid      (lsb_broadcast_valid),
    .LSB_value      (lsb_broadcast_value),
    .LSB_RobId      (lsb_broadcast_RobId),
    .rob_rs1_ready   (rob_to_issue_rs1_ready),
    .rob_rs1_value   (rob_to_issue_rs1_value),
    .rob_rs2_ready   (rob_to_issue_rs2_ready),
    .rob_rs2_value   (rob_to_issue_rs2_value),
    .Vj_from_reg     (reg_to_issue_Vj),
    .Rj_from_reg     (reg_to_issue_Rj),
    .Qj_from_reg     (reg_to_issue_Qj),
    .Vk_from_reg     (reg_to_issue_Vk),
    .Rk_from_reg     (reg_to_issue_Rk),
    .Qk_from_reg     (reg_to_issue_Qk),
    .rob_next        (rob_next        ),
    .rob_send_enable (issue_to_rob_valid),
    .reg_send_enable (issue_to_reg_valid),
    .send_RobId      (issue_send_RobId),
    .rs_send_enable  (issue_to_rs_valid),
    .Vj      (issue_Vj),
    .Rj      (issue_Rj),
    .Qj      (issue_Qj),
    .Vk      (issue_Vk),
    .Rk      (issue_Rk),
    .Qk      (issue_Qk),
    .lsb_send_enable (issue_to_lsb_valid)
  );
  
  RS u_RS(
  	.clk           (clk_in        ),
    .rst           (rst_in        ),
    .rdy           (rdy_in        ),
    .issue_valid   (issue_to_rs_valid),
    .issue_op      (issue_op),
    .issue_Vj      (issue_Vj),
    .issue_Rj      (issue_Rj),
    .issue_Qj      (issue_Qj),
    .issue_Vk      (issue_Vk),
    .issue_Rk      (issue_Rk),
    .issue_Qk      (issue_Qk),
    .issue_Imm     (issue_Imm),
    .issue_DestRob (issue_send_RobId),
    .issue_CurPC   (issue_CurPc),
    .exc_valid     (fu_broadcast_valid),
    .exc_RobId     (fu_broadcast_RobId),
    .exc_value     (fu_broadcast_value),
    .FU_enable     (rs_to_fu_valid),
    .FU_op         (rs_to_fu_op),
    .FU_Vj         (rs_to_fu_Vj),
    .FU_Vk         (rs_to_fu_Vk),
    .FU_Imm        (rs_to_fu_Imm),
    .FU_DestRob    (rs_to_fu_DestRob),
    .FU_CurPC      (rs_to_fu_CurPc),
    .LSB_valid     (lsb_broadcast_valid),
    .LSB_RobId     (lsb_broadcast_RobId),
    .LSB_value     (lsb_broadcast_value),
    .jump_flag     (jump_flag     ),
    .RS_next_full  (rs_next_full)
  );
  
  RegFile u_RegFile(
  	.clk          (clk_in       ),
    .rst          (rst_in       ),
    .rdy          (rdy_in       ),
    .rs1          (if_to_reg_rs1),
    .rs2          (if_to_reg_rs2),
    .Vj_to_issue  (reg_to_issue_Vj),
    .Rj_to_issue  (reg_to_issue_Rj),
    .Qj_to_issue  (reg_to_issue_Qj),
    .Vk_to_issue  (reg_to_issue_Vk),
    .Rk_to_issue  (reg_to_issue_Rk),
    .Qk_to_issue  (reg_to_issue_Qk),
    .commit_valid (rob_to_reg_valid),
    .commit_dest  (rob_to_reg_dest),
    .commit_value (rob_to_reg_value),
    .commit_RobId (rob_to_reg_RobId),
    .rename_valid (issue_to_reg_valid),
    .issue_rd     (issue_rd),
    .issue_RobId  (issue_send_RobId),
    .jump_flag    (jump_flag    )
  );

  ROB u_ROB(
  	.clk             (clk_in          ),
    .rst             (rst_in          ),
    .rdy             (rdy_in          ),
    .issue_valid     (issue_to_rob_valid),
    .issue_op        (issue_op),
    .issue_dest      (issue_rd),
    .issue_pc        (issue_CurPc),
    .issue_pred      (issue_to_rob_pred),
    .exc_valid       (fu_broadcast_valid),
    .exc_value       (fu_broadcast_value),
    .exc_toPC        (fu_broadcast_toPC),
    .exc_RobId       (fu_broadcast_RobId),
    .lsb_valid       (lsb_broadcast_valid),
    .lsb_value       (lsb_broadcast_value),
    .lsb_RobId       (lsb_broadcast_RobId),
    .store_valid     (lsb_to_rob_store_valid),
    .store_RodId     (lsb_to_rob_store_RobId),
    .reg_enable      (rob_to_reg_valid),
    .reg_index       (rob_to_reg_dest),
    .reg_RobId       (rob_to_reg_RobId),
    .reg_value       (rob_to_reg_value),
    .jump_flag       (jump_flag       ),
    .if_toPC         (rob_to_if_pc),
    .update_pred_enable    (update_pred_valid),
    .update_pred_index     (update_pred_index),
    .update_pred_need_jump (update_pred_need_jump),
    .lsb_begin_store (rob_to_lsb_valid),
    .lsb_store_RobId (rob_to_lsb_RobId),
    .issue_query_rs1 (reg_to_issue_Qj),
    .issue_query_rs2 (reg_to_issue_Qk),
    .rs1_ready       (rob_to_issue_rs1_ready),
    .rs1_value       (rob_to_issue_rs1_value),
    .rs2_ready       (rob_to_issue_rs2_ready),
    .rs2_value       (rob_to_issue_rs2_value),
    .rob_next_full   (rob_next_full   ),
    .rob_next        (rob_next        ),
    .rob_top_id      (rob_top_id      )
  );

  LSBuffer u_LSBuffer(
  	.clk           (clk_in        ),
    .rst           (rst_in        ),
    .rdy           (rdy_in        ),
    .jump_flag     (jump_flag     ),
    .rob_top_id    (rob_top_id    ),
    .issue_valid   (issue_to_lsb_valid),
    .issue_op      (issue_op),
    .issue_Vj      (issue_Vj),
    .issue_Rj      (issue_Rj),
    .issue_Qj      (issue_Qj),
    .issue_Vk      (issue_Vk),
    .issue_Rk      (issue_Rk),
    .issue_Qk      (issue_Qk),
    .issue_Imm     (issue_Imm),
    .issue_DestRob (issue_send_RobId),
    .rob_committed (rob_to_lsb_valid),
    .rob_RobId     (rob_to_lsb_RobId),
    .exc_valid     (fu_broadcast_valid),
    .exc_RobId     (fu_broadcast_RobId),
    .exc_value     (fu_broadcast_value),
    .mem_enable    (lsb_to_mem_valid),
    .op_size       (lsb_to_mem_size),
    .mem_addr      (lsb_to_mem_addr),
    .mem_wdata     (lsb_to_mem_store_data),
    .mem_wr_tag    (lsb_to_mem_wr_tag),
    .mem_success   (mem_to_lsb_valid),
    .mem_rdata     (mem_to_lsb_load_data),
    .B_enable      (lsb_broadcast_valid),
    .B_RobId       (lsb_broadcast_RobId),
    .B_value       (lsb_broadcast_value),
    .store_enable  (lsb_to_rob_store_valid),
    .store_RobId   (lsb_to_rob_store_RobId),
    .LSB_next_full (lsb_next_full )
  );
endmodule

`endif