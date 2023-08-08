----------------------------------------------------------------------
----                                                              ----
---- Modular Multiplier                                           ----
---- RSA Public Key Cryptography IP Core                          ----
----                                                              ----
---- This file is part of the BasicRSA project                    ----
---- http://www.opencores.org/                                    ----
----                                                              ----
---- To Do:                                                       ----
---- - Speed and efficiency improvements                          ----
---- - Possible revisions for good engineering/coding practices   ----
----                                                              ----
---- Author(s):                                                   ----
---- - Steven R. McQueen, srmcqueen@opencores.org                 ----
----                                                              ----
----------------------------------------------------------------------
----                                                              ----
---- Copyright (C) 2003 Steven R. McQueen                         ----
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

-- This module implements the modular multiplier for the RSA Public Key Cypher. It expects 
-- to receive a multiplicand on th MPAND bus, a multiplier on the MPLIER bus, and a modulus
-- on the MODULUS bus. The multiplier and multiplicand must have a value less than the modulus.
--
-- A Shift-and-Add algorithm is used in this module. For each bit of the multiplier, the
-- multiplicand value is shifted. For each '1' bit of the multiplier, the shifted multiplicand
-- value is added    to the product. To ensure that the product is always expressed as a remainder
-- two subtractions are performed on the product, P2 = P1-modulus, and P3 = P1-(2*modulus).
-- The high-order bits of these results are used to determine whether P sould be copied from
-- P1, P2, or P3. 
--
-- The operation ends when all '1' bits in the multiplier have been used.
--
-- Comments, questions and suggestions may be directed to the author at srmcqueen@mcqueentech.com.
--
--
----------------------------------------------------------------------
--
-- This module has been refactored for security.
-- 
-- Additional label inputs have been introduced to indicate to indicate whether an operand is confidential.
-- The timing is always independent of any confidential data.
-- The label of the product output is high, as soon as at least one operand is confidential.
--
-- Contact: lucas.deutschmann@rptu.de
--


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.MATH_REAL.LOG2;
USE IEEE.MATH_REAL.CEIL;


entity modmult_sc is
    Generic (MPWID: integer := 32);
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
end modmult_sc;


architecture modmult_sc1 of modmult_sc is

signal mpreg: std_logic_vector(MPWID-1 downto 0);
signal mcreg, mcreg1, mcreg2: std_logic_vector(MPWID+1 downto 0);
signal modreg1, modreg2: std_logic_vector(MPWID+1 downto 0);
signal prodreg, prodreg1, prodreg2, prodreg3, prodreg4: std_logic_vector(MPWID+1 downto 0);
signal mpand_label_q, mplier_label_q, modulus_label_q : std_logic;

signal modstate: std_logic_vector(1 downto 0);
signal first: std_logic;

signal secure: std_logic;
signal timer: std_logic_vector(INTEGER(CEIL(LOG2(REAL(MPWID))))-1 downto 0);

begin

    -- final result...
    product <= prodreg4(MPWID-1 downto 0);

    -- add shifted value if place bit is '1', copy original if place bit is '0'
    with mpreg(0) select
        prodreg1 <= prodreg + mcreg when '1',
                    prodreg when others;

    -- subtract modulus and subtract modulus * 2.
    prodreg2 <= prodreg1 - modreg1;
    prodreg3 <= prodreg1 - modreg2;

    -- negative results mean that we subtracted too much...
    modstate <= prodreg3(mpwid+1) & prodreg2(mpwid+1);
    
    -- select the correct modular result and copy it....
    with modstate select
        prodreg4 <= prodreg1 when "11",
                    prodreg2 when "10",
                    prodreg3 when others;

    -- meanwhile, subtract the modulus from the shifted multiplicand...
    mcreg1 <= mcreg - modreg1;
    
    -- select the correct modular value and copy it.
    with mcreg1(MPWID) select
        mcreg2 <= mcreg when '1',
                  mcreg1 when others;

    ready <= secure when (mpand_label_q and mplier_label_q) = '1' else first;

    product_label <= mpand_label_q or mplier_label_q or modulus_label_q;

    combine: process (clk, reset) is

    begin
    
        if reset = '1' then
            first <= '1';
            mpreg <= (others => '0');
            mcreg <= (others => '0');
            modreg1 <= (others => '0');
            modreg2 <= (others => '0');
            prodreg <= (others => '0');
            mpand_label_q   <= '1';
            mplier_label_q  <= '1';
            modulus_label_q <= '1';
        elsif rising_edge(clk) then
            if first = '1' and secure = '1' then
            -- First time through, set up registers to start multiplication procedure
            -- Input values are sampled only once
                if ds = '1' then
                    if mplier_label = '1' then --multiplier is confidential
                        mpreg <= mpand;
                        mcreg <= "00" & mplier;
                    elsif mpand_label = '1' then --multiplicand is confidential
                        mpreg <= mplier;
                        mcreg <= "00" & mpand;
                    elsif mplier > mpand then -- use smaller input for a better performance
                        mpreg <= mpand;
                        mcreg <= "00" & mplier;
                    else
                        mpreg <= mplier;
                        mcreg <= "00" & mpand;
                    end if;
                    modreg1 <= "00" & modulus;
                    modreg2 <= '0' & modulus & '0';
                    prodreg <= (others => '0');
                    first <= '0';
                    mpand_label_q   <= mpand_label;
                    mplier_label_q  <= mplier_label;
                    modulus_label_q <= modulus_label;
                end if;
            else
            -- when all bits have been shifted out of the multiplicand, operation is over
            -- Note: this leads to at least one waste cycle per multiplication
            -- Change: Can also terminate as soon as mpreg = 1
                if mpreg(MPWID-1 downto 1) = 0 then
                    first <= '1';
                else
                -- shift the multiplicand left one bit
                    mcreg <= mcreg2(MPWID downto 0) & '0';
                -- shift the multiplier right one bit
                    mpreg <= '0' & mpreg(MPWID-1 downto 1);
                -- copy intermediate product
                    prodreg <= prodreg4;
                end if;
            end if;
        end if;

    end process combine;

    -- Dummy counter to ensure a data-independent latency if both factors are confidential 
    cnt_dit: process (clk, reset) is
    
    begin
    
        if reset = '1' then
            secure <= '1';
            timer <= (others => '0');
        elsif rising_edge(clk) then
            if ds = '1' and first = '1' and secure = '1' then
                if (mplier_label and mpand_label) = '1' then
                    timer <= (others => '1');
                    secure <= '0';
                end if;
            elsif timer > 0 then
                timer <= timer - 1;
            else
                secure <= '1';
            end if;
        end if;
        
    end process cnt_dit;

end modmult_sc1;
