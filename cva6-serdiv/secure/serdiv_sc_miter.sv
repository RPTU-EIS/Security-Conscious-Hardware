module serdiv_sc_miter import ariane_pkg::*;
  #(parameter WIDTH = 64)
  (
  input clk,
  input rst,

  input  logic [TRANS_ID_BITS-1:0] id_i,
  input  logic [WIDTH-1:0]         op_a_i1, op_a_i2,
  input  logic [WIDTH-1:0]         op_b_i1, op_b_i2,
  input  logic [1:0]               opcode_i,
  input  logic                     in_vld_i,
  input  logic                     flush_i,
  input  logic                     out_rdy_i,
  input  logic                     op_a_label_i1, op_a_label_i2,
  input  logic                     op_b_label_i1, op_b_label_i2,

  output logic                     in_rdy_o1, in_rdy_o2,
  output logic                     out_vld_o1, out_vld_o2,
  output logic [TRANS_ID_BITS-1:0] id_o1, id_o2,
  output logic [WIDTH-1:0]         res_o1, res_o2,
  output logic                     res_label_o1, res_label_o2

  );

  serdiv_sc #(.WIDTH(WIDTH)) U1
  (
    .clk_i(clk),
    .rst_ni(rst),
    .id_i(id_i),
    .op_a_i(op_a_i1),
    .op_b_i(op_b_i1),
    .opcode_i(opcode_i),
    .in_vld_i(in_vld_i),
    .flush_i(flush_i),
    .out_rdy_i(out_rdy_i),
    .op_a_label_i(op_a_label_i1),
    .op_b_label_i(op_b_label_i1),

    .in_rdy_o(in_rdy_o1),
    .out_vld_o(out_vld_o1),
    .id_o(id_o1),
    .res_o(res_o1),
    .res_label_o(res_label_o1)
  );

  serdiv_sc #(.WIDTH(WIDTH)) U2
  (
    .clk_i(clk),
    .rst_ni(rst),
    .id_i(id_i),
    .op_a_i(op_a_i2),
    .op_b_i(op_b_i2),
    .opcode_i(opcode_i),
    .in_vld_i(in_vld_i),
    .flush_i(flush_i),
    .out_rdy_i(out_rdy_i),
    .op_a_label_i(op_a_label_i1),
    .op_b_label_i(op_b_label_i1),

    .in_rdy_o(in_rdy_o2),
    .out_vld_o(out_vld_o2),
    .id_o(id_o2),
    .res_o(res_o2),
    .res_label_o(res_label_o2)
  );

endmodule;
