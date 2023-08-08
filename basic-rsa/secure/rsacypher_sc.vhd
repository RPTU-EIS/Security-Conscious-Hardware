----------------------------------------------------------------------
----                                                              ----
---- Basic RSA Public Key Cryptography IP Core                    ----
----                                                              ----
---- Implementation of BasicRSA IP core according to              ----
---- BasicRSA IP core specification document.                     ----
----                                                              ----
---- To Do:                                                       ----
---- -                                                            ----
----                                                              ----
---- Author(s):                                                   ----
---- - Steven R. McQueen, srmcqueen@opencores.org                 ----
----                                                              ----
----------------------------------------------------------------------
----                                                              ----
---- Copyright (C) 2001 Authors and OPENCORES.ORG                 ----
----                                                              ----
---- This source file may be used and distributed without         ----
---- restriction provided that this copyright statement is not    ----
---- removed from the file and that any derivative work contains  ----
---- the original copyright notice and the associated disclaimer. ----
----                                                              ----
---- This source file is free software; you can redistribute it   ----
---- and/or modify it under the terms of the GNU Lesser General   ----
---- Public License as published by the Free Software Foundation; ----
---- either version 2.1 of the License, or (at your option) any   ----
---- later version.                                               ----
----                                                              ----
---- This source is distributed in the hope that it will be       ----
---- useful, but WITHOUT ANY WARRANTY; without even the implied   ----
---- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ----
---- PURPOSE. See the GNU Lesser General Public License for more  ----
---- details.                                                     ----
----                                                              ----
---- You should have received a copy of the GNU Lesser General    ----
---- Public License along with this source; if not, download it   ----
---- from http://www.opencores.org/lgpl.shtml                     ----
----                                                              ----
----------------------------------------------------------------------
--
-- CVS Revision History
--
-- $Log: not supported by cvs2svn $
--

-- This module implements the RSA Public Key Cypher. It expects to receive the data block
-- to be encrypted or decrypted on the indata bus, the exponent to be used on the inExp bus,
-- and the modulus on the inMod bus. The data block must have a value less than the modulus.
-- It may be worth noting that in practice the exponent is not restricted to the size of the
-- modulus, as would be implied by the bus sizes used in this design. This design must
-- therefore be regarded as a demonstration only.
--
-- A Square-and-Multiply algorithm is used in this module. For each bit of the exponent, the
-- message value is squared. For each '1' bit of the exponent, the message value is multiplied
-- by the result of the squaring operation. The operation ends when there are no more '1'
-- bits in the exponent. Unfortunately, the squaring multiplication must be performed whether
-- the corresponding exponent bit is '1' or '0', so very little is gained by skipping the
-- multiplication of the data value. A multiplication is performed for every significant bit
-- in the exponent.
--
-- Comments, questions and suggestions may be directed to the author at srmcqueen@mcqueentech.com.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

                                                                    
entity RSACypher_sc is
    Generic (KEYSIZE: integer := 32);
    Port (indata       : in  std_logic_vector(KEYSIZE-1 downto 0);
          inExp        : in  std_logic_vector(KEYSIZE-1 downto 0);
          inMod        : in  std_logic_vector(KEYSIZE-1 downto 0);
          cypher       : out std_logic_vector(KEYSIZE-1 downto 0);
          clk          : in  std_logic;
          ds           : in  std_logic;
          reset        : in  std_logic;
          ready        : out std_logic;
          indata_label : in  std_logic;
          inExp_label  : in  std_logic;
          inMod_label  : in  std_logic;
          cypher_label : out std_logic
          );
end RSACypher_sc;


architecture Behavioral of RSACypher_sc is

component modmult_sc is
    Generic (MPWID: integer);
    Port ( mpand         : in  std_logic_vector(MPWID-1 downto 0);
           mplier        : in  std_logic_vector(MPWID-1 downto 0);
           modulus       : in  std_logic_vector(MPWID-1 downto 0);
           product       : out std_logic_vector(MPWID-1 downto 0);
           clk           : in  std_logic;
           ds            : in  std_logic;
           reset         : in  std_logic;
           ready         : out std_logic;
           mpand_label   : in  std_logic;
           mplier_label  : in  std_logic;
           modulus_label : in  std_logic;
           product_label : out std_logic
           );
end component;

signal modreg   : std_logic_vector(KEYSIZE-1 downto 0);   -- store the modulus value during operation
signal root     : std_logic_vector(KEYSIZE-1 downto 0);   -- value to be squared
signal square   : std_logic_vector(KEYSIZE-1 downto 0);   -- result of square operation
signal sqrin    : std_logic_vector(KEYSIZE-1 downto 0);   -- 1 or copy of root
signal tempin   : std_logic_vector(KEYSIZE-1 downto 0);   -- 1 or copy of square
signal tempout  : std_logic_vector(KEYSIZE-1 downto 0);   -- result of multiplication
signal count    : std_logic_vector(KEYSIZE-1 downto 0);   -- working copy of exponent

signal count_sc : std_logic_vector(KEYSIZE-1 downto 0);   -- Dummy counter for confidential exponents

signal multrdy, sqrrdy, bothrdy : std_logic;              -- signals to indicate completion of multiplications
signal bothgo                   : std_logic;              -- signal to trigger multiplication and squaring
signal done                     : std_logic;              -- signal to indicate encryption complete

signal data_label_q    : std_logic; 
signal exp_label_q     : std_logic;
signal mod_label_q     : std_logic;

signal root_label_q    : std_logic;
signal sqrin_label_q   : std_logic;
signal tempin_label_q  : std_logic;
signal square_label_d  : std_logic;
signal tempout_label_d : std_logic;


begin

    cypher_label <= '1' when (data_label_q or exp_label_q or mod_label_q) = '1' else '0';
    
    ready <= done;
    bothrdy <= multrdy and sqrrdy;
    
    -- Modular multiplier to produce products
    modmultiply: modmult_sc
    Generic Map(MPWID => KEYSIZE)
    Port Map(mpand         => tempin,
             mplier        => sqrin,
             modulus       => modreg,
             product       => tempout,
             clk           => clk,
             ds            => bothgo,
             reset         => reset,
             ready         => multrdy,
             mpand_label   => tempin_label_q,
             mplier_label  => sqrin_label_q,
             modulus_label => mod_label_q,
             product_label => tempout_label_d
             );

    -- Modular multiplier to take care of squaring operations
    modsqr: modmult_sc
    Generic Map(MPWID => KEYSIZE)
    Port Map(mpand         => root,
             mplier        => root,
             modulus       => modreg,
             product       => square,
             clk           => clk,
             ds            => bothgo,
             reset         => reset,
             ready         => sqrrdy,
             mpand_label   => root_label_q,
             mplier_label  => root_label_q,
             modulus_label => mod_label_q,
             product_label => square_label_d);


    --counter manager process tracks counter and enable flags
    mngcount: process (clk, reset) is
    begin
        
        if reset = '1' then
        
            count        <= (others => '0');
            count_sc     <= (others => '0');
            cypher       <= (others => '0');
            done         <= '1';
            data_label_q <= '0';
            exp_label_q  <= '0';
            
        elsif rising_edge(clk) then
        
            if done = '1' then
            -- first time through
                if ds = '1' then
                    count <= '0' & inExp(KEYSIZE-1 downto 1);
                    if inExp_label = '1' then
                        count_sc <=  ('0', others => '1');
                    else
                        count_sc <= (others => '0');
                    end if;
                    cypher <= (others => '0');
                    done <= '0';
                    data_label_q <= indata_label;
                    exp_label_q  <= inExp_label;
                end if;
            -- after first time
            elsif count = 0 and count_sc = 0 then
                if bothrdy = '1' and bothgo = '0' then
                    cypher <= tempout;        -- set output value
                    done <= '1';
                end if;
            elsif bothrdy = '1' then
                if bothgo = '0' then
                    count    <= '0' & count(KEYSIZE-1 downto 1);
                    count_sc <= '0' & count_sc(KEYSIZE-1 downto 1);
                end if;
            end if;
        end if;

    end process mngcount;


    -- This process sets the input values for the squaring multitplier
    setupsqr: process (clk, reset) is
    begin
        
        if reset = '1' then
        
            root         <= (others => '0');
            root_label_q <= '0';
            modreg       <= (others => '0');
            mod_label_q  <= '0';
            
        elsif rising_edge(clk) then
        
            if done = '1' then
                if ds = '1' then
        -- first time through, input is sampled only once
                    modreg <= inMod;
                    mod_label_q <= inMod_label;
                    root <= indata;
                    root_label_q <= indata_label;
                end if;
        -- after first time, square result is fed back to multiplier
            elsif bothrdy = '1' and bothgo = '0' then
                root <= square;
                root_label_q <= data_label_q or mod_label_q;
            end if;
        end if;

    end process setupsqr;
    
    
    -- This process sets input values for the product multiplier
    setupmult: process (clk, reset) is
    begin
        
        if reset = '1' then
        
            tempin         <= (others => '0');
            tempin_label_q <= '0';
            sqrin          <= (others => '0');
            sqrin_label_q  <= '0';
            
        elsif rising_edge(clk) then
        
            if done = '1' then
                if ds = '1' then
        -- first time through, input is sampled only once
        -- if the least significant bit of the exponent is '1' then we seed the
        -- multiplier with the message value. Otherwise, we seed it with 1.
        -- The square is set to 1, so the result of the first multiplication will be
        -- either 1 or the initial message value
                    if inExp(0) = '1' then
                        tempin <= indata;
                        tempin_label_q <= indata_label or inExp_label;
                    else
                        tempin(KEYSIZE-1 downto 1) <= (others => '0');
                        tempin(0) <= '1';
                        tempin_label_q <= inExp_label;
                    end if;
                    sqrin(KEYSIZE-1 downto 1) <= (others => '0');
                    sqrin(0) <= '1';
                    sqrin_label_q <= '0';
                end if;
        -- after first time, the multiplication and square results are fed back through the multiplier.
        -- The counter (exponent) has been shifted one bit to the right
        -- If the least significant bit of the exponent is '1' the result of the most recent
        -- squaring operation is fed to the multiplier.
        -- Otherwise, the square value is set to 1 to indicate no multiplication.
            elsif bothrdy = '1' and bothgo = '0' then
                tempin <= tempout;
                tempin_label_q <= tempout_label_d;
                if count(0) = '1' then
                    sqrin <= square;
                    sqrin_label_q <= square_label_d;
                else
                    sqrin(KEYSIZE-1 downto 1) <= (others => '0');
                    sqrin(0) <= '1';
                    sqrin_label_q <= square_label_d;
                end if;
            end if;
        end if;

    end process setupmult;
    
    
    -- this process enables the multipliers when it is safe to do so
    crypto: process (clk, reset) is
    begin
        
        if reset = '1' then
            bothgo <= '0';
        elsif rising_edge(clk) then
        
            -- first time through - automatically trigger first multiplier cycle
            if done = '1' then
                if ds = '1' then
                    bothgo <= '1';
                end if;
                
            -- after first time, trigger multipliers when both operations are complete
            elsif count > 0 then
                if bothrdy = '1' then
                    bothgo <= '1';
                end if;
                
            -- continue if the exponent is confidential
            elsif count_sc > 0 then
                if bothrdy = '1' then
                    bothgo <= '1';
                end if;
            end if;
            
            -- when multipliers have been started, disable multiplier inputs
            if bothgo = '1' then
                bothgo <= '0';
            end if;
            
        end if;

    end process crypto;

end Behavioral;
