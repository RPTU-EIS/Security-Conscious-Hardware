`timescale 1 ns/1 ns

module serdiv_sc_tb import ariane_pkg::*; #(
  parameter WIDTH       = 64
) (
  output logic                      clk_i,
  output logic                      rst_ni,
  // input IF
  output logic [TRANS_ID_BITS-1:0]  id_i,
  output logic [WIDTH-1:0]          op_a_i,
  output logic [WIDTH-1:0]          op_b_i,
  output logic [1:0]                opcode_i, // 0: udiv, 2: urem, 1: div, 3: rem
  // handshake
  output logic                      in_vld_i,
  input  logic                      in_rdy_o,
  output logic                      flush_i,
  // output IF
  input  logic                      out_vld_o,
  output logic                      out_rdy_i,
  input  logic [TRANS_ID_BITS-1:0]  id_o,
  input  logic [WIDTH-1:0]          res_o,
  // operand labels
  output logic                      op_a_label_i,
  output logic                      op_b_label_i,
  input  logic                      res_label_o
);
  
  always #10 clk_i = ~clk_i;
  
  // TB always sends new data as soon as DUT is ready
  // Assign is not possible due to combinational loop
  always_ff @(posedge clk_i) in_vld_i <= in_rdy_o;
  
  // TB is always ready to receive the result
  assign out_rdy_i = out_vld_o;
  
  int N = 10000;
  
  int seed = 1;
  int mean = 0;
  int std_deviation = 10000;
  
  int var_a, var_b;
  

  serdiv_sc #(WIDTH) dut (.*);
  
  initial begin 

    clk_i        <=  1'b0;
    rst_ni       <=  1'b0;
    
    id_i         <=    '0;
    flush_i      <=  1'b0;
    
    opcode_i     <= 2'b00;
    
    op_a_i       <=    '0;
    op_a_label_i <=  1'b1;
    op_b_i       <=    '0;
    op_b_label_i <=  1'b0;
    
    #40
    
    rst_ni <= 1'b1;
    
    for (int i = 0; i < N; i++) begin
        std::randomize(opcode_i);
        //std::randomize(op_a_i);
        //std::randomize(op_b_i);
        var_a = $dist_normal(seed, mean, std_deviation);
        var_b = $dist_normal(seed, mean, std_deviation);
        //$display("%0d -> var_a %d var_b %d", i, var_a, var_b);
        op_a_i = var_a;
        op_b_i = var_b;
        #40
        wait(in_rdy_o == 1);
    end
    
    // Subtract 70ns offset and 40ns overhead in between operations
    $display("Final simulation time (clock cycles): %0t", ($realtime-70ns-(N-1)*40ns) / 20000);
    
    $finish;
    
  end

endmodule
