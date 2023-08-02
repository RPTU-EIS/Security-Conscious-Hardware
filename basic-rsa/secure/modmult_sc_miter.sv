module modmult_miter
  #(parameter MPWID = 32)
  (
  input clk,
  input rst,

  input logic [MPWID-1:0] mpand1, mpand2,
  input logic [MPWID-1:0] mplier1, mplier2,
  input logic [MPWID-1:0] modulus1, modulus2,

  input logic ds,
  input logic mplier_label1, mplier_label2,
  input logic mpand_label1, mpand_label2,
  input logic modulus_label1, modulus_label2

  );

  modmult_sc #(.MPWID(MPWID)) U1
  (
    .clk(clk),
    .reset(rst),
    .mpand(mpand1),
    .mplier(mplier1),
    .modulus(modulus1),
    .product(),
    .ds(ds),
    .ready(),
    .mplier_label(mplier_label1),
    .mpand_label(mpand_label1),
    .modulus_label(modulus_label1)
  );

  modmult_sc #(.MPWID(MPWID)) U2
  (
    .clk(clk),
    .reset(rst),
    .mpand(mpand2),
    .mplier(mplier2),
    .modulus(modulus2),
    .product(),
    .ds(ds),
    .ready(),
    .mplier_label(mplier_label2),
    .mpand_label(mpand_label2),
    .modulus_label(modulus_label2)
  );

endmodule;
