module rsacypher_sc_miter
  #(parameter KEYSIZE = 32)
  (
  input clk,
  input rst,

  input  [KEYSIZE-1:0] indata1, indata2,
  input  [KEYSIZE-1:0] inExp1, inExp2,
  input  [KEYSIZE-1:0] inMod1, inMod2,

  input  ds,
  input  indata1_label, indata2_label,
  input  inExp1_label, inExp2_label,
  input  inMod1_label, inMod2_label
  );

  RSACypher_sc #(.KEYSIZE(KEYSIZE)) U1
  (
    .clk(clk),
    .reset(rst),
    .indata(indata1),
    .inExp(inExp1),
    .inMod(inMod1),
    .cypher(),
    .ds(ds),
    .ready(),
    .indata_label(indata1_label),
    .inExp_label(inExp1_label),
    .inMod_label(inMod1_label)
  );

  RSACypher_sc #(.KEYSIZE(KEYSIZE)) U2
  (
    .clk(clk),
    .reset(rst),
    .indata(indata2),
    .inExp(inExp2),
    .inMod(inMod2),
    .cypher(),
    .ds(ds),
    .ready(),
    .indata_label(indata2_label),
    .inExp_label(inExp2_label),
    .inMod_label(inMod2_label)
  );

endmodule;
