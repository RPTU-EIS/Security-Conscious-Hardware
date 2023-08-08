`timescale 1 ns/1 ns

module rsacypher_sc_tb 
  #(parameter KEYSIZE = 32) 
  (
  output logic               clk,
  output logic               reset,
  output logic [KEYSIZE-1:0] indata,
  output logic [KEYSIZE-1:0] inExp,
  output logic [KEYSIZE-1:0] inMod,
  output logic               ds,
  input  logic               ready,
  output logic               indata_label,
  output logic               inExp_label,
  output logic               inMod_label,
  input  logic [KEYSIZE-1:0] cypher,
  input  logic               cypher_label
);
  
  always #10 clk = ~clk;
  
  // TB always sends new data as soon as DUT is ready
  assign ds = ready;
  
  int N = 10000;
  
  int seed = 1;
  int mean = 0;
  int std_deviation = 10000;
  
  int var_b, var_e, var_m;
  

  RSACypher_sc #(KEYSIZE) dut (
    .clk(clk),
    .reset(reset),
    .indata(indata),
    .inExp(inExp),
    .inMod(inMod),
    .ds(ds),
    .ready(ready),
    .indata_label(indata_label),
    .inExp_label(inExp_label),
    .inMod_label(inMod_label),
    .cypher(cypher),
    .cypher_label(cypher_label)
  );
  
  initial begin 

    clk          <=  1'b0;
    reset        <=  1'b1;
    
    indata       <=    '0;
    indata_label <=  1'b1;
    inExp        <=    '0;
    inExp_label  <=  1'b1;
    inMod        <=    '0;
    inMod_label  <=  1'b1;
    
    #40
    
    reset <= 1'b0;
    for (int i = 0; i < N; i++) begin
        //std::randomize(indata);
        //std::randomize(inExp);
        //std::randomize(inMod) with {inMod > indata;};
        var_b = $dist_normal(seed, mean, std_deviation);
        var_b = var_b < 0 ? -var_b : var_b;
        var_e = $dist_normal(seed, mean, std_deviation);
        var_e = var_e < 0 ? -var_e : var_e;
        var_m = $dist_normal(seed, mean, std_deviation);
        var_m = var_m < 0 ? -var_m : var_m;
        //$display("%0d -> var_b %d var_e %d var_m %d", i, var_b, var_e, var_m);
        if (var_b < var_m) begin
          indata = var_b;
          inMod = var_m;
        end else begin
          indata = var_m;
          inMod = var_b;
        end
        inExp = var_e;
        //$display("%0d -> base %d exp %d mod %d", i, indata, inExp, inMod);
        #40
        wait(ready == 1);
    end
   
   // Wait until next positive clock edge
    #20
    
    // First operation starts at 50 ns, no overhead in between
    $display("Final simulation time (clock cycles): %0t", ($realtime-50ns) / 20000);
    
    $finish;
    
  end

endmodule
