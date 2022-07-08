-------------------------------------------------------------------------------
-- Title      : CRC Package
-------------------------------------------------------------------------------
-- File       : CrcPkg.vhd
-- Author     : Kurtis Nishimura
-------------------------------------------------------------------------------
-- Description: This package defines a few functions that are useful for 
--              computing CRC values.
--              
--              crc32Parallel<N>Byte defines parallel implementations of the
--              CRC32 algorithm with the "standard" CRC32 polynomial: 0x04C11DB7
--              Byte widths of 1-8 are currently supported.
--               
--              To see how the parallel statements are generated, see here:
--              http://www.slac.stanford.edu/~kurtisn/Crc32/Crc32.cpp
--              This is an implementation of the ideas found here:
--              http://outputlogic.com/my-stuff/circuit-cellar-january-2010-crc.pdf
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.UtilityPkg.all;

package CrcPkg is 

   function crcByteLookup (inByte : slv; constant poly : slv) return slv;
   function crcLfsrShift (lfsr : slv; constant poly : slv; input : sl) return slv;
   
   --Specific CRC32 parallel implementations with the standard polynomial: 0x04C11DB7
   function crc32Parallel1Byte (crcCur : slv(31 downto 0); data : slv(7 downto 0)) return slv;
   function crc32Parallel2Byte (crcCur : slv(31 downto 0); data : slv(15 downto 0)) return slv;
   function crc32Parallel3Byte (crcCur : slv(31 downto 0); data : slv(23 downto 0)) return slv;
   function crc32Parallel4Byte (crcCur : slv(31 downto 0); data : slv(31 downto 0)) return slv;
   function crc32Parallel5Byte (crcCur : slv(31 downto 0); data : slv(39 downto 0)) return slv;
   function crc32Parallel6Byte (crcCur : slv(31 downto 0); data : slv(47 downto 0)) return slv;
   function crc32Parallel7Byte (crcCur : slv(31 downto 0); data : slv(55 downto 0)) return slv;
   function crc32Parallel8Byte (crcCur : slv(31 downto 0); data : slv(63 downto 0)) return slv;
   
end CrcPkg;

package body CrcPkg is

   -------------------------------------------------------------------------------------------------
   -- Implements an N tap linear feedback shift operation suitable for CRC implementations
   -- This uses a Galois LFSR and inherently assumes the highest polynomial term is 1
   -- (e.g., in CRC32 the x^32 term is implicit, so the standard polynomial 0x04C11DB7 is
   --  good enough). 
   --
   -- Size of LFSR is variable and determined by length of lfsr parameter, but size of the
   -- lfsr and polynomial should match.
   --
   -- The shift is in the direction of increasing index (left shift for decending, right for ascending)
   -- New data bits are shifted in from the lsb-end.
   --
   -- As written, this can be called N-times to implement CRC calculations, but requires an 
   -- a message augmented with zeroes to match standard CRC calculations.  This makes it a 
   -- "nondirect" implementation.
   -------------------------------------------------------------------------------------------------

   function crcLfsrShift (lfsr : slv; constant poly : slv; input : sl) return slv is
      variable retVar : slv(lfsr'range) := (others => '0');
   begin
      if (lfsr'ascending) then
         for i in lfsr'range loop
            if poly(i) = '1' then
               if (i = 0) then
                  retVar(i) := lfsr(lfsr'right) xor input;  
               else
                  retVar(i) := lfsr(lfsr'right) xor lfsr(i-1);
               end if;
            else
               if (i = 0) then
                  retVar(i) := input;
               else
                  retVar(i) := lfsr(i-1);
               end if;
            end if;
         end loop;
      else
         for i in lfsr'range loop
            if poly(i) = '1' then
               if (i = 0) then
                  retVar(i) := lfsr(lfsr'left) xor input;  
               else
                  retVar(i) := lfsr(lfsr'left) xor lfsr(i-1);               
               end if;
            else
               if (i = 0) then
                  retVar(i) := input;
               else
                  retVar(i) := lfsr(i-1);
               end if;
            end if;
         end loop;
      end if;

      return retVar;
   end function;  

   -------------------------------------------------------------------------------------------------
   -- Implements an lookup of CRC values for a given data byte.  This is used in many 
   -- "table driven" implementations of CRC.
   -- Supports both ascending or descending bit orders.
   -------------------------------------------------------------------------------------------------

   function crcByteLookup (inByte : slv; constant poly : slv) return slv is 
      variable retVar : slv(poly'range) := (others => '0');
   begin
      assert (inByte'high-inByte'low = 7) report "crcByteLookup() - input must be byte-sized" severity failure;

      if (inByte'ascending) then
         retVar(retVar'right-7 to retVar'right) := inByte;
         retVar(0 to retVar'right-8)            := (others => '0');
      
         for b in 7 downto 0 loop
            if (retVar(retVar'right) = '1') then
               retVar := ('0' & retVar(0 to retVar'right-1)) xor poly;
            else
               retVar := ('0' & retVar(0 to retVar'right-1));
            end if;
         end loop;
               
      else
         retVar(retVar'left downto retVar'left-7) := inByte;
         retVar(retVar'left-8 downto 0)           := (others => '0');

         for b in 7 downto 0 loop
            if (retVar(retVar'left) = '1') then
               retVar := (retVar(retVar'left-1 downto 0) & '0') xor poly;
            else
               retVar := (retVar(retVar'left-1 downto 0) & '0');
            end if;
         end loop;
      end if;

      return retVar;
 
   end function; 

   ---------------------------------------------------------
   -- Parallel CRC implementations for various byte widths 
   ---------------------------------------------------------   
   function crc32Parallel1Byte (crcCur : slv(31 downto 0); data : slv(7 downto 0)) return slv is
      variable retVar : slv(31 downto 0) := (others => '0');
   begin
      retVar(0) := data(0) xor data(6) xor crcCur(24) xor crcCur(30);
      retVar(1) := data(0) xor data(1) xor data(6) xor data(7) xor crcCur(24) xor crcCur(25) xor crcCur(30) xor crcCur(31);
      retVar(2) := data(0) xor data(1) xor data(2) xor data(6) xor data(7) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(30) xor crcCur(31);
      retVar(3) := data(1) xor data(2) xor data(3) xor data(7) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(31);
      retVar(4) := data(0) xor data(2) xor data(3) xor data(4) xor data(6) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      retVar(5) := data(0) xor data(1) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(6) := data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(7) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(7) := data(0) xor data(2) xor data(3) xor data(5) xor data(7) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(31);
      retVar(8) := data(0) xor data(1) xor data(3) xor data(4) xor crcCur(0) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28);
      retVar(9) := data(1) xor data(2) xor data(4) xor data(5) xor crcCur(1) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(29);
      retVar(10) := data(0) xor data(2) xor data(3) xor data(5) xor crcCur(2) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(29);
      retVar(11) := data(0) xor data(1) xor data(3) xor data(4) xor crcCur(3) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28);
      retVar(12) := data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor crcCur(4) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      retVar(13) := data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor crcCur(5) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(14) := data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor crcCur(6) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(15) := data(3) xor data(4) xor data(5) xor data(7) xor crcCur(7) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(16) := data(0) xor data(4) xor data(5) xor crcCur(8) xor crcCur(24) xor crcCur(28) xor crcCur(29);
      retVar(17) := data(1) xor data(5) xor data(6) xor crcCur(9) xor crcCur(25) xor crcCur(29) xor crcCur(30);
      retVar(18) := data(2) xor data(6) xor data(7) xor crcCur(10) xor crcCur(26) xor crcCur(30) xor crcCur(31);
      retVar(19) := data(3) xor data(7) xor crcCur(11) xor crcCur(27) xor crcCur(31);
      retVar(20) := data(4) xor crcCur(12) xor crcCur(28);
      retVar(21) := data(5) xor crcCur(13) xor crcCur(29);
      retVar(22) := data(0) xor crcCur(14) xor crcCur(24);
      retVar(23) := data(0) xor data(1) xor data(6) xor crcCur(15) xor crcCur(24) xor crcCur(25) xor crcCur(30);
      retVar(24) := data(1) xor data(2) xor data(7) xor crcCur(16) xor crcCur(25) xor crcCur(26) xor crcCur(31);
      retVar(25) := data(2) xor data(3) xor crcCur(17) xor crcCur(26) xor crcCur(27);
      retVar(26) := data(0) xor data(3) xor data(4) xor data(6) xor crcCur(18) xor crcCur(24) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      retVar(27) := data(1) xor data(4) xor data(5) xor data(7) xor crcCur(19) xor crcCur(25) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(28) := data(2) xor data(5) xor data(6) xor crcCur(20) xor crcCur(26) xor crcCur(29) xor crcCur(30);
      retVar(29) := data(3) xor data(6) xor data(7) xor crcCur(21) xor crcCur(27) xor crcCur(30) xor crcCur(31);
      retVar(30) := data(4) xor data(7) xor crcCur(22) xor crcCur(28) xor crcCur(31);
      retVar(31) := data(5) xor crcCur(23) xor crcCur(29);
      return retVar;      
   end function;   

   function crc32Parallel2Byte (crcCur : slv(31 downto 0); data : slv(15 downto 0)) return slv is
      variable retVar : slv(31 downto 0) := (others => '0');
   begin
      retVar(0) := data(0) xor data(6) xor data(9) xor data(10) xor data(12) xor crcCur(16) xor crcCur(22) xor crcCur(25) xor crcCur(26) xor crcCur(28);
      retVar(1) := data(0) xor data(1) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor crcCur(16) xor crcCur(17) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(29);
      retVar(2) := data(0) xor data(1) xor data(2) xor data(6) xor data(7) xor data(8) xor data(9) xor data(13) xor data(14) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(29) xor crcCur(30);
      retVar(3) := data(1) xor data(2) xor data(3) xor data(7) xor data(8) xor data(9) xor data(10) xor data(14) xor data(15) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(30) xor crcCur(31);
      retVar(4) := data(0) xor data(2) xor data(3) xor data(4) xor data(6) xor data(8) xor data(11) xor data(12) xor data(15) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(24) xor crcCur(27) xor crcCur(28) xor crcCur(31);
      retVar(5) := data(0) xor data(1) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(26) xor crcCur(29);
      retVar(6) := data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(27) xor crcCur(30);
      retVar(7) := data(0) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(10) xor data(15) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(31);
      retVar(8) := data(0) xor data(1) xor data(3) xor data(4) xor data(8) xor data(10) xor data(11) xor data(12) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(28);
      retVar(9) := data(1) xor data(2) xor data(4) xor data(5) xor data(9) xor data(11) xor data(12) xor data(13) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(21) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(29);
      retVar(10) := data(0) xor data(2) xor data(3) xor data(5) xor data(9) xor data(13) xor data(14) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(25) xor crcCur(29) xor crcCur(30);
      retVar(11) := data(0) xor data(1) xor data(3) xor data(4) xor data(9) xor data(12) xor data(14) xor data(15) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(25) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(12) := data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(25) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(13) := data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(26) xor crcCur(29) xor crcCur(30);
      retVar(14) := data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(15) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(27) xor crcCur(30) xor crcCur(31);
      retVar(15) := data(3) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(15) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(28) xor crcCur(31);
      retVar(16) := data(0) xor data(4) xor data(5) xor data(8) xor data(12) xor data(13) xor crcCur(0) xor crcCur(16) xor crcCur(20) xor crcCur(21) xor crcCur(24) xor crcCur(28) xor crcCur(29);
      retVar(17) := data(1) xor data(5) xor data(6) xor data(9) xor data(13) xor data(14) xor crcCur(1) xor crcCur(17) xor crcCur(21) xor crcCur(22) xor crcCur(25) xor crcCur(29) xor crcCur(30);
      retVar(18) := data(2) xor data(6) xor data(7) xor data(10) xor data(14) xor data(15) xor crcCur(2) xor crcCur(18) xor crcCur(22) xor crcCur(23) xor crcCur(26) xor crcCur(30) xor crcCur(31);
      retVar(19) := data(3) xor data(7) xor data(8) xor data(11) xor data(15) xor crcCur(3) xor crcCur(19) xor crcCur(23) xor crcCur(24) xor crcCur(27) xor crcCur(31);
      retVar(20) := data(4) xor data(8) xor data(9) xor data(12) xor crcCur(4) xor crcCur(20) xor crcCur(24) xor crcCur(25) xor crcCur(28);
      retVar(21) := data(5) xor data(9) xor data(10) xor data(13) xor crcCur(5) xor crcCur(21) xor crcCur(25) xor crcCur(26) xor crcCur(29);
      retVar(22) := data(0) xor data(9) xor data(11) xor data(12) xor data(14) xor crcCur(6) xor crcCur(16) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      retVar(23) := data(0) xor data(1) xor data(6) xor data(9) xor data(13) xor data(15) xor crcCur(7) xor crcCur(16) xor crcCur(17) xor crcCur(22) xor crcCur(25) xor crcCur(29) xor crcCur(31);
      retVar(24) := data(1) xor data(2) xor data(7) xor data(10) xor data(14) xor crcCur(8) xor crcCur(17) xor crcCur(18) xor crcCur(23) xor crcCur(26) xor crcCur(30);
      retVar(25) := data(2) xor data(3) xor data(8) xor data(11) xor data(15) xor crcCur(9) xor crcCur(18) xor crcCur(19) xor crcCur(24) xor crcCur(27) xor crcCur(31);
      retVar(26) := data(0) xor data(3) xor data(4) xor data(6) xor data(10) xor crcCur(10) xor crcCur(16) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(26);
      retVar(27) := data(1) xor data(4) xor data(5) xor data(7) xor data(11) xor crcCur(11) xor crcCur(17) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(27);
      retVar(28) := data(2) xor data(5) xor data(6) xor data(8) xor data(12) xor crcCur(12) xor crcCur(18) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(28);
      retVar(29) := data(3) xor data(6) xor data(7) xor data(9) xor data(13) xor crcCur(13) xor crcCur(19) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(29);
      retVar(30) := data(4) xor data(7) xor data(8) xor data(10) xor data(14) xor crcCur(14) xor crcCur(20) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(30);
      retVar(31) := data(5) xor data(8) xor data(9) xor data(11) xor data(15) xor crcCur(15) xor crcCur(21) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(31);
      return retVar;      
   end function;   

   function crc32Parallel3Byte (crcCur : slv(31 downto 0); data : slv(23 downto 0)) return slv is
      variable retVar : slv(31 downto 0) := (others => '0');
   begin
      retVar(0) := data(0) xor data(6) xor data(9) xor data(10) xor data(12) xor data(16) xor crcCur(8) xor crcCur(14) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(24);
      retVar(1) := data(0) xor data(1) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(16) xor data(17) xor crcCur(8) xor crcCur(9) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(24) xor crcCur(25);
      retVar(2) := data(0) xor data(1) xor data(2) xor data(6) xor data(7) xor data(8) xor data(9) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(25) xor crcCur(26);
      retVar(3) := data(1) xor data(2) xor data(3) xor data(7) xor data(8) xor data(9) xor data(10) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(27);
      retVar(4) := data(0) xor data(2) xor data(3) xor data(4) xor data(6) xor data(8) xor data(11) xor data(12) xor data(15) xor data(18) xor data(19) xor data(20) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(16) xor crcCur(19) xor crcCur(20) xor crcCur(23) xor crcCur(26) xor crcCur(27) xor crcCur(28);
      retVar(5) := data(0) xor data(1) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(19) xor data(20) xor data(21) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(18) xor crcCur(21) xor crcCur(27) xor crcCur(28) xor crcCur(29);
      retVar(6) := data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(20) xor data(21) xor data(22) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(19) xor crcCur(22) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      retVar(7) := data(0) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(10) xor data(15) xor data(16) xor data(21) xor data(22) xor data(23) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(23) xor crcCur(24) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(8) := data(0) xor data(1) xor data(3) xor data(4) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(22) xor data(23) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(25) xor crcCur(30) xor crcCur(31);
      retVar(9) := data(1) xor data(2) xor data(4) xor data(5) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(23) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(13) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(26) xor crcCur(31);
      retVar(10) := data(0) xor data(2) xor data(3) xor data(5) xor data(9) xor data(13) xor data(14) xor data(16) xor data(19) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(17) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(27);
      retVar(11) := data(0) xor data(1) xor data(3) xor data(4) xor data(9) xor data(12) xor data(14) xor data(15) xor data(16) xor data(17) xor data(20) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(17) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(28);
      retVar(12) := data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(17) xor data(18) xor data(21) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(17) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(29);
      retVar(13) := data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(18) xor data(19) xor data(22) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(18) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(30);
      retVar(14) := data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(20) xor data(23) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(19) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(31);
      retVar(15) := data(3) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(20) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(28) xor crcCur(29);
      retVar(16) := data(0) xor data(4) xor data(5) xor data(8) xor data(12) xor data(13) xor data(17) xor data(19) xor data(21) xor data(22) xor crcCur(8) xor crcCur(12) xor crcCur(13) xor crcCur(16) xor crcCur(20) xor crcCur(21) xor crcCur(25) xor crcCur(27) xor crcCur(29) xor crcCur(30);
      retVar(17) := data(1) xor data(5) xor data(6) xor data(9) xor data(13) xor data(14) xor data(18) xor data(20) xor data(22) xor data(23) xor crcCur(9) xor crcCur(13) xor crcCur(14) xor crcCur(17) xor crcCur(21) xor crcCur(22) xor crcCur(26) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(18) := data(2) xor data(6) xor data(7) xor data(10) xor data(14) xor data(15) xor data(19) xor data(21) xor data(23) xor crcCur(10) xor crcCur(14) xor crcCur(15) xor crcCur(18) xor crcCur(22) xor crcCur(23) xor crcCur(27) xor crcCur(29) xor crcCur(31);
      retVar(19) := data(3) xor data(7) xor data(8) xor data(11) xor data(15) xor data(16) xor data(20) xor data(22) xor crcCur(11) xor crcCur(15) xor crcCur(16) xor crcCur(19) xor crcCur(23) xor crcCur(24) xor crcCur(28) xor crcCur(30);
      retVar(20) := data(4) xor data(8) xor data(9) xor data(12) xor data(16) xor data(17) xor data(21) xor data(23) xor crcCur(12) xor crcCur(16) xor crcCur(17) xor crcCur(20) xor crcCur(24) xor crcCur(25) xor crcCur(29) xor crcCur(31);
      retVar(21) := data(5) xor data(9) xor data(10) xor data(13) xor data(17) xor data(18) xor data(22) xor crcCur(13) xor crcCur(17) xor crcCur(18) xor crcCur(21) xor crcCur(25) xor crcCur(26) xor crcCur(30);
      retVar(22) := data(0) xor data(9) xor data(11) xor data(12) xor data(14) xor data(16) xor data(18) xor data(19) xor data(23) xor crcCur(8) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(31);
      retVar(23) := data(0) xor data(1) xor data(6) xor data(9) xor data(13) xor data(15) xor data(16) xor data(17) xor data(19) xor data(20) xor crcCur(8) xor crcCur(9) xor crcCur(14) xor crcCur(17) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28);
      retVar(24) := data(1) xor data(2) xor data(7) xor data(10) xor data(14) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor crcCur(0) xor crcCur(9) xor crcCur(10) xor crcCur(15) xor crcCur(18) xor crcCur(22) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(29);
      retVar(25) := data(2) xor data(3) xor data(8) xor data(11) xor data(15) xor data(17) xor data(18) xor data(19) xor data(21) xor data(22) xor crcCur(1) xor crcCur(10) xor crcCur(11) xor crcCur(16) xor crcCur(19) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(30);
      retVar(26) := data(0) xor data(3) xor data(4) xor data(6) xor data(10) xor data(18) xor data(19) xor data(20) xor data(22) xor data(23) xor crcCur(2) xor crcCur(8) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(18) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(27) := data(1) xor data(4) xor data(5) xor data(7) xor data(11) xor data(19) xor data(20) xor data(21) xor data(23) xor crcCur(3) xor crcCur(9) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(19) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(28) := data(2) xor data(5) xor data(6) xor data(8) xor data(12) xor data(20) xor data(21) xor data(22) xor crcCur(4) xor crcCur(10) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(20) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      retVar(29) := data(3) xor data(6) xor data(7) xor data(9) xor data(13) xor data(21) xor data(22) xor data(23) xor crcCur(5) xor crcCur(11) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(21) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(30) := data(4) xor data(7) xor data(8) xor data(10) xor data(14) xor data(22) xor data(23) xor crcCur(6) xor crcCur(12) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(22) xor crcCur(30) xor crcCur(31);
      retVar(31) := data(5) xor data(8) xor data(9) xor data(11) xor data(15) xor data(23) xor crcCur(7) xor crcCur(13) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(23) xor crcCur(31);
      return retVar;      
   end function;   

   function crc32Parallel4Byte (crcCur : slv(31 downto 0); data : slv(31 downto 0)) return slv is
      variable retVar : slv(31 downto 0) := (others => '0');
   begin
      retVar(0) := data(0) xor data(6) xor data(9) xor data(10) xor data(12) xor data(16) xor data(24) xor data(25) xor data(26) xor data(28) xor data(29) xor data(30) xor data(31) xor crcCur(0) xor crcCur(6) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(16) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(1) := data(0) xor data(1) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(16) xor data(17) xor data(24) xor data(27) xor data(28) xor crcCur(0) xor crcCur(1) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(16) xor crcCur(17) xor crcCur(24) xor crcCur(27) xor crcCur(28);
      retVar(2) := data(0) xor data(1) xor data(2) xor data(6) xor data(7) xor data(8) xor data(9) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(24) xor data(26) xor data(30) xor data(31) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(24) xor crcCur(26) xor crcCur(30) xor crcCur(31);
      retVar(3) := data(1) xor data(2) xor data(3) xor data(7) xor data(8) xor data(9) xor data(10) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(25) xor data(27) xor data(31) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(25) xor crcCur(27) xor crcCur(31);
      retVar(4) := data(0) xor data(2) xor data(3) xor data(4) xor data(6) xor data(8) xor data(11) xor data(12) xor data(15) xor data(18) xor data(19) xor data(20) xor data(24) xor data(25) xor data(29) xor data(30) xor data(31) xor crcCur(0) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(6) xor crcCur(8) xor crcCur(11) xor crcCur(12) xor crcCur(15) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(24) xor crcCur(25) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(5) := data(0) xor data(1) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(19) xor data(20) xor data(21) xor data(24) xor data(28) xor data(29) xor crcCur(0) xor crcCur(1) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(7) xor crcCur(10) xor crcCur(13) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(24) xor crcCur(28) xor crcCur(29);
      retVar(6) := data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(20) xor data(21) xor data(22) xor data(25) xor data(29) xor data(30) xor crcCur(1) xor crcCur(2) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(11) xor crcCur(14) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(25) xor crcCur(29) xor crcCur(30);
      retVar(7) := data(0) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(10) xor data(15) xor data(16) xor data(21) xor data(22) xor data(23) xor data(24) xor data(25) xor data(28) xor data(29) xor crcCur(0) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(7) xor crcCur(8) xor crcCur(10) xor crcCur(15) xor crcCur(16) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(28) xor crcCur(29);
      retVar(8) := data(0) xor data(1) xor data(3) xor data(4) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(22) xor data(23) xor data(28) xor data(31) xor crcCur(0) xor crcCur(1) xor crcCur(3) xor crcCur(4) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(17) xor crcCur(22) xor crcCur(23) xor crcCur(28) xor crcCur(31);
      retVar(9) := data(1) xor data(2) xor data(4) xor data(5) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(23) xor data(24) xor data(29) xor crcCur(1) xor crcCur(2) xor crcCur(4) xor crcCur(5) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(18) xor crcCur(23) xor crcCur(24) xor crcCur(29);
      retVar(10) := data(0) xor data(2) xor data(3) xor data(5) xor data(9) xor data(13) xor data(14) xor data(16) xor data(19) xor data(26) xor data(28) xor data(29) xor data(31) xor crcCur(0) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(9) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(19) xor crcCur(26) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(11) := data(0) xor data(1) xor data(3) xor data(4) xor data(9) xor data(12) xor data(14) xor data(15) xor data(16) xor data(17) xor data(20) xor data(24) xor data(25) xor data(26) xor data(27) xor data(28) xor data(31) xor crcCur(0) xor crcCur(1) xor crcCur(3) xor crcCur(4) xor crcCur(9) xor crcCur(12) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(20) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(31);
      retVar(12) := data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(17) xor data(18) xor data(21) xor data(24) xor data(27) xor data(30) xor data(31) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(9) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(21) xor crcCur(24) xor crcCur(27) xor crcCur(30) xor crcCur(31);
      retVar(13) := data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(18) xor data(19) xor data(22) xor data(25) xor data(28) xor data(31) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(6) xor crcCur(7) xor crcCur(10) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(22) xor crcCur(25) xor crcCur(28) xor crcCur(31);
      retVar(14) := data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(20) xor data(23) xor data(26) xor data(29) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(11) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(23) xor crcCur(26) xor crcCur(29);
      retVar(15) := data(3) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21) xor data(24) xor data(27) xor data(30) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(12) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(20) xor crcCur(21) xor crcCur(24) xor crcCur(27) xor crcCur(30);
      retVar(16) := data(0) xor data(4) xor data(5) xor data(8) xor data(12) xor data(13) xor data(17) xor data(19) xor data(21) xor data(22) xor data(24) xor data(26) xor data(29) xor data(30) xor crcCur(0) xor crcCur(4) xor crcCur(5) xor crcCur(8) xor crcCur(12) xor crcCur(13) xor crcCur(17) xor crcCur(19) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(26) xor crcCur(29) xor crcCur(30);
      retVar(17) := data(1) xor data(5) xor data(6) xor data(9) xor data(13) xor data(14) xor data(18) xor data(20) xor data(22) xor data(23) xor data(25) xor data(27) xor data(30) xor data(31) xor crcCur(1) xor crcCur(5) xor crcCur(6) xor crcCur(9) xor crcCur(13) xor crcCur(14) xor crcCur(18) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(27) xor crcCur(30) xor crcCur(31);
      retVar(18) := data(2) xor data(6) xor data(7) xor data(10) xor data(14) xor data(15) xor data(19) xor data(21) xor data(23) xor data(24) xor data(26) xor data(28) xor data(31) xor crcCur(2) xor crcCur(6) xor crcCur(7) xor crcCur(10) xor crcCur(14) xor crcCur(15) xor crcCur(19) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(28) xor crcCur(31);
      retVar(19) := data(3) xor data(7) xor data(8) xor data(11) xor data(15) xor data(16) xor data(20) xor data(22) xor data(24) xor data(25) xor data(27) xor data(29) xor crcCur(3) xor crcCur(7) xor crcCur(8) xor crcCur(11) xor crcCur(15) xor crcCur(16) xor crcCur(20) xor crcCur(22) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(29);
      retVar(20) := data(4) xor data(8) xor data(9) xor data(12) xor data(16) xor data(17) xor data(21) xor data(23) xor data(25) xor data(26) xor data(28) xor data(30) xor crcCur(4) xor crcCur(8) xor crcCur(9) xor crcCur(12) xor crcCur(16) xor crcCur(17) xor crcCur(21) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(30);
      retVar(21) := data(5) xor data(9) xor data(10) xor data(13) xor data(17) xor data(18) xor data(22) xor data(24) xor data(26) xor data(27) xor data(29) xor data(31) xor crcCur(5) xor crcCur(9) xor crcCur(10) xor crcCur(13) xor crcCur(17) xor crcCur(18) xor crcCur(22) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(31);
      retVar(22) := data(0) xor data(9) xor data(11) xor data(12) xor data(14) xor data(16) xor data(18) xor data(19) xor data(23) xor data(24) xor data(26) xor data(27) xor data(29) xor data(31) xor crcCur(0) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(31);
      retVar(23) := data(0) xor data(1) xor data(6) xor data(9) xor data(13) xor data(15) xor data(16) xor data(17) xor data(19) xor data(20) xor data(26) xor data(27) xor data(29) xor data(31) xor crcCur(0) xor crcCur(1) xor crcCur(6) xor crcCur(9) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(31);
      retVar(24) := data(1) xor data(2) xor data(7) xor data(10) xor data(14) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(27) xor data(28) xor data(30) xor crcCur(1) xor crcCur(2) xor crcCur(7) xor crcCur(10) xor crcCur(14) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(21) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      retVar(25) := data(2) xor data(3) xor data(8) xor data(11) xor data(15) xor data(17) xor data(18) xor data(19) xor data(21) xor data(22) xor data(28) xor data(29) xor data(31) xor crcCur(2) xor crcCur(3) xor crcCur(8) xor crcCur(11) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(22) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(26) := data(0) xor data(3) xor data(4) xor data(6) xor data(10) xor data(18) xor data(19) xor data(20) xor data(22) xor data(23) xor data(24) xor data(25) xor data(26) xor data(28) xor data(31) xor crcCur(0) xor crcCur(3) xor crcCur(4) xor crcCur(6) xor crcCur(10) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(31);
      retVar(27) := data(1) xor data(4) xor data(5) xor data(7) xor data(11) xor data(19) xor data(20) xor data(21) xor data(23) xor data(24) xor data(25) xor data(26) xor data(27) xor data(29) xor crcCur(1) xor crcCur(4) xor crcCur(5) xor crcCur(7) xor crcCur(11) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(29);
      retVar(28) := data(2) xor data(5) xor data(6) xor data(8) xor data(12) xor data(20) xor data(21) xor data(22) xor data(24) xor data(25) xor data(26) xor data(27) xor data(28) xor data(30) xor crcCur(2) xor crcCur(5) xor crcCur(6) xor crcCur(8) xor crcCur(12) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      retVar(29) := data(3) xor data(6) xor data(7) xor data(9) xor data(13) xor data(21) xor data(22) xor data(23) xor data(25) xor data(26) xor data(27) xor data(28) xor data(29) xor data(31) xor crcCur(3) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(13) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(30) := data(4) xor data(7) xor data(8) xor data(10) xor data(14) xor data(22) xor data(23) xor data(24) xor data(26) xor data(27) xor data(28) xor data(29) xor data(30) xor crcCur(4) xor crcCur(7) xor crcCur(8) xor crcCur(10) xor crcCur(14) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      retVar(31) := data(5) xor data(8) xor data(9) xor data(11) xor data(15) xor data(23) xor data(24) xor data(25) xor data(27) xor data(28) xor data(29) xor data(30) xor data(31) xor crcCur(5) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(15) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      return retVar;      
   end function;   

   function crc32Parallel5Byte (crcCur : slv(31 downto 0); data : slv(39 downto 0)) return slv is
      variable retVar : slv(31 downto 0) := (others => '0');
   begin
      retVar(0) := data(0) xor data(6) xor data(9) xor data(10) xor data(12) xor data(16) xor data(24) xor data(25) xor data(26) xor data(28) xor data(29) xor data(30) xor data(31) xor data(32) xor data(34) xor data(37) xor crcCur(1) xor crcCur(2) xor crcCur(4) xor crcCur(8) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(29);
      retVar(1) := data(0) xor data(1) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(16) xor data(17) xor data(24) xor data(27) xor data(28) xor data(33) xor data(34) xor data(35) xor data(37) xor data(38) xor crcCur(1) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(8) xor crcCur(9) xor crcCur(16) xor crcCur(19) xor crcCur(20) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(30);
      retVar(2) := data(0) xor data(1) xor data(2) xor data(6) xor data(7) xor data(8) xor data(9) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(24) xor data(26) xor data(30) xor data(31) xor data(32) xor data(35) xor data(36) xor data(37) xor data(38) xor data(39) xor crcCur(0) xor crcCur(1) xor crcCur(5) xor crcCur(6) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(16) xor crcCur(18) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(3) := data(1) xor data(2) xor data(3) xor data(7) xor data(8) xor data(9) xor data(10) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(25) xor data(27) xor data(31) xor data(32) xor data(33) xor data(36) xor data(37) xor data(38) xor data(39) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(17) xor crcCur(19) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(4) := data(0) xor data(2) xor data(3) xor data(4) xor data(6) xor data(8) xor data(11) xor data(12) xor data(15) xor data(18) xor data(19) xor data(20) xor data(24) xor data(25) xor data(29) xor data(30) xor data(31) xor data(33) xor data(38) xor data(39) xor crcCur(0) xor crcCur(3) xor crcCur(4) xor crcCur(7) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(16) xor crcCur(17) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(30) xor crcCur(31);
      retVar(5) := data(0) xor data(1) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(19) xor data(20) xor data(21) xor data(24) xor data(28) xor data(29) xor data(37) xor data(39) xor crcCur(2) xor crcCur(5) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(16) xor crcCur(20) xor crcCur(21) xor crcCur(29) xor crcCur(31);
      retVar(6) := data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(20) xor data(21) xor data(22) xor data(25) xor data(29) xor data(30) xor data(38) xor crcCur(0) xor crcCur(3) xor crcCur(6) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(17) xor crcCur(21) xor crcCur(22) xor crcCur(30);
      retVar(7) := data(0) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(10) xor data(15) xor data(16) xor data(21) xor data(22) xor data(23) xor data(24) xor data(25) xor data(28) xor data(29) xor data(32) xor data(34) xor data(37) xor data(39) xor crcCur(0) xor crcCur(2) xor crcCur(7) xor crcCur(8) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(20) xor crcCur(21) xor crcCur(24) xor crcCur(26) xor crcCur(29) xor crcCur(31);
      retVar(8) := data(0) xor data(1) xor data(3) xor data(4) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(22) xor data(23) xor data(28) xor data(31) xor data(32) xor data(33) xor data(34) xor data(35) xor data(37) xor data(38) xor crcCur(0) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(9) xor crcCur(14) xor crcCur(15) xor crcCur(20) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(30);
      retVar(9) := data(1) xor data(2) xor data(4) xor data(5) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(23) xor data(24) xor data(29) xor data(32) xor data(33) xor data(34) xor data(35) xor data(36) xor data(38) xor data(39) xor crcCur(1) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(10) xor crcCur(15) xor crcCur(16) xor crcCur(21) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(10) := data(0) xor data(2) xor data(3) xor data(5) xor data(9) xor data(13) xor data(14) xor data(16) xor data(19) xor data(26) xor data(28) xor data(29) xor data(31) xor data(32) xor data(33) xor data(35) xor data(36) xor data(39) xor crcCur(1) xor crcCur(5) xor crcCur(6) xor crcCur(8) xor crcCur(11) xor crcCur(18) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(31);
      retVar(11) := data(0) xor data(1) xor data(3) xor data(4) xor data(9) xor data(12) xor data(14) xor data(15) xor data(16) xor data(17) xor data(20) xor data(24) xor data(25) xor data(26) xor data(27) xor data(28) xor data(31) xor data(33) xor data(36) xor crcCur(1) xor crcCur(4) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(12) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(23) xor crcCur(25) xor crcCur(28);
      retVar(12) := data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(17) xor data(18) xor data(21) xor data(24) xor data(27) xor data(30) xor data(31) xor crcCur(1) xor crcCur(4) xor crcCur(5) xor crcCur(7) xor crcCur(9) xor crcCur(10) xor crcCur(13) xor crcCur(16) xor crcCur(19) xor crcCur(22) xor crcCur(23);
      retVar(13) := data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(18) xor data(19) xor data(22) xor data(25) xor data(28) xor data(31) xor data(32) xor crcCur(2) xor crcCur(5) xor crcCur(6) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(14) xor crcCur(17) xor crcCur(20) xor crcCur(23) xor crcCur(24);
      retVar(14) := data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(20) xor data(23) xor data(26) xor data(29) xor data(32) xor data(33) xor crcCur(0) xor crcCur(3) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(15) xor crcCur(18) xor crcCur(21) xor crcCur(24) xor crcCur(25);
      retVar(15) := data(3) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21) xor data(24) xor data(27) xor data(30) xor data(33) xor data(34) xor crcCur(0) xor crcCur(1) xor crcCur(4) xor crcCur(7) xor crcCur(8) xor crcCur(10) xor crcCur(12) xor crcCur(13) xor crcCur(16) xor crcCur(19) xor crcCur(22) xor crcCur(25) xor crcCur(26);
      retVar(16) := data(0) xor data(4) xor data(5) xor data(8) xor data(12) xor data(13) xor data(17) xor data(19) xor data(21) xor data(22) xor data(24) xor data(26) xor data(29) xor data(30) xor data(32) xor data(35) xor data(37) xor crcCur(0) xor crcCur(4) xor crcCur(5) xor crcCur(9) xor crcCur(11) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(18) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(27) xor crcCur(29);
      retVar(17) := data(1) xor data(5) xor data(6) xor data(9) xor data(13) xor data(14) xor data(18) xor data(20) xor data(22) xor data(23) xor data(25) xor data(27) xor data(30) xor data(31) xor data(33) xor data(36) xor data(38) xor crcCur(1) xor crcCur(5) xor crcCur(6) xor crcCur(10) xor crcCur(12) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(19) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(28) xor crcCur(30);
      retVar(18) := data(2) xor data(6) xor data(7) xor data(10) xor data(14) xor data(15) xor data(19) xor data(21) xor data(23) xor data(24) xor data(26) xor data(28) xor data(31) xor data(32) xor data(34) xor data(37) xor data(39) xor crcCur(2) xor crcCur(6) xor crcCur(7) xor crcCur(11) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(20) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(29) xor crcCur(31);
      retVar(19) := data(3) xor data(7) xor data(8) xor data(11) xor data(15) xor data(16) xor data(20) xor data(22) xor data(24) xor data(25) xor data(27) xor data(29) xor data(32) xor data(33) xor data(35) xor data(38) xor crcCur(0) xor crcCur(3) xor crcCur(7) xor crcCur(8) xor crcCur(12) xor crcCur(14) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(21) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(30);
      retVar(20) := data(4) xor data(8) xor data(9) xor data(12) xor data(16) xor data(17) xor data(21) xor data(23) xor data(25) xor data(26) xor data(28) xor data(30) xor data(33) xor data(34) xor data(36) xor data(39) xor crcCur(0) xor crcCur(1) xor crcCur(4) xor crcCur(8) xor crcCur(9) xor crcCur(13) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(22) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(31);
      retVar(21) := data(5) xor data(9) xor data(10) xor data(13) xor data(17) xor data(18) xor data(22) xor data(24) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(37) xor crcCur(1) xor crcCur(2) xor crcCur(5) xor crcCur(9) xor crcCur(10) xor crcCur(14) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(23) xor crcCur(26) xor crcCur(27) xor crcCur(29);
      retVar(22) := data(0) xor data(9) xor data(11) xor data(12) xor data(14) xor data(16) xor data(18) xor data(19) xor data(23) xor data(24) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(36) xor data(37) xor data(38) xor crcCur(1) xor crcCur(3) xor crcCur(4) xor crcCur(6) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(23) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      retVar(23) := data(0) xor data(1) xor data(6) xor data(9) xor data(13) xor data(15) xor data(16) xor data(17) xor data(19) xor data(20) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(36) xor data(38) xor data(39) xor crcCur(1) xor crcCur(5) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(23) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(24) := data(1) xor data(2) xor data(7) xor data(10) xor data(14) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(27) xor data(28) xor data(30) xor data(32) xor data(35) xor data(36) xor data(37) xor data(39) xor crcCur(2) xor crcCur(6) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(13) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(24) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(25) := data(2) xor data(3) xor data(8) xor data(11) xor data(15) xor data(17) xor data(18) xor data(19) xor data(21) xor data(22) xor data(28) xor data(29) xor data(31) xor data(33) xor data(36) xor data(37) xor data(38) xor crcCur(0) xor crcCur(3) xor crcCur(7) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(14) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(25) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      retVar(26) := data(0) xor data(3) xor data(4) xor data(6) xor data(10) xor data(18) xor data(19) xor data(20) xor data(22) xor data(23) xor data(24) xor data(25) xor data(26) xor data(28) xor data(31) xor data(38) xor data(39) xor crcCur(2) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(23) xor crcCur(30) xor crcCur(31);
      retVar(27) := data(1) xor data(4) xor data(5) xor data(7) xor data(11) xor data(19) xor data(20) xor data(21) xor data(23) xor data(24) xor data(25) xor data(26) xor data(27) xor data(29) xor data(32) xor data(39) xor crcCur(3) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(24) xor crcCur(31);
      retVar(28) := data(2) xor data(5) xor data(6) xor data(8) xor data(12) xor data(20) xor data(21) xor data(22) xor data(24) xor data(25) xor data(26) xor data(27) xor data(28) xor data(30) xor data(33) xor crcCur(0) xor crcCur(4) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(25);
      retVar(29) := data(3) xor data(6) xor data(7) xor data(9) xor data(13) xor data(21) xor data(22) xor data(23) xor data(25) xor data(26) xor data(27) xor data(28) xor data(29) xor data(31) xor data(34) xor crcCur(1) xor crcCur(5) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(26);
      retVar(30) := data(4) xor data(7) xor data(8) xor data(10) xor data(14) xor data(22) xor data(23) xor data(24) xor data(26) xor data(27) xor data(28) xor data(29) xor data(30) xor data(32) xor data(35) xor crcCur(0) xor crcCur(2) xor crcCur(6) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(27);
      retVar(31) := data(5) xor data(8) xor data(9) xor data(11) xor data(15) xor data(23) xor data(24) xor data(25) xor data(27) xor data(28) xor data(29) xor data(30) xor data(31) xor data(33) xor data(36) xor crcCur(0) xor crcCur(1) xor crcCur(3) xor crcCur(7) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(28);
      return retVar;      
   end function;   

   function crc32Parallel6Byte (crcCur : slv(31 downto 0); data : slv(47 downto 0)) return slv is
      variable retVar : slv(31 downto 0) := (others => '0');
   begin
      retVar(0) := data(0) xor data(6) xor data(9) xor data(10) xor data(12) xor data(16) xor data(24) xor data(25) xor data(26) xor data(28) xor data(29) xor data(30) xor data(31) xor data(32) xor data(34) xor data(37) xor data(44) xor data(45) xor data(47) xor crcCur(0) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(21) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(1) := data(0) xor data(1) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(16) xor data(17) xor data(24) xor data(27) xor data(28) xor data(33) xor data(34) xor data(35) xor data(37) xor data(38) xor data(44) xor data(46) xor data(47) xor crcCur(0) xor crcCur(1) xor crcCur(8) xor crcCur(11) xor crcCur(12) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(22) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(2) := data(0) xor data(1) xor data(2) xor data(6) xor data(7) xor data(8) xor data(9) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(24) xor data(26) xor data(30) xor data(31) xor data(32) xor data(35) xor data(36) xor data(37) xor data(38) xor data(39) xor data(44) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(8) xor crcCur(10) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(28);
      retVar(3) := data(1) xor data(2) xor data(3) xor data(7) xor data(8) xor data(9) xor data(10) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(25) xor data(27) xor data(31) xor data(32) xor data(33) xor data(36) xor data(37) xor data(38) xor data(39) xor data(40) xor data(45) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(9) xor crcCur(11) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(29);
      retVar(4) := data(0) xor data(2) xor data(3) xor data(4) xor data(6) xor data(8) xor data(11) xor data(12) xor data(15) xor data(18) xor data(19) xor data(20) xor data(24) xor data(25) xor data(29) xor data(30) xor data(31) xor data(33) xor data(38) xor data(39) xor data(40) xor data(41) xor data(44) xor data(45) xor data(46) xor data(47) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(8) xor crcCur(9) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(5) := data(0) xor data(1) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(19) xor data(20) xor data(21) xor data(24) xor data(28) xor data(29) xor data(37) xor data(39) xor data(40) xor data(41) xor data(42) xor data(44) xor data(46) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(8) xor crcCur(12) xor crcCur(13) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(30);
      retVar(6) := data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(20) xor data(21) xor data(22) xor data(25) xor data(29) xor data(30) xor data(38) xor data(40) xor data(41) xor data(42) xor data(43) xor data(45) xor data(47) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(9) xor crcCur(13) xor crcCur(14) xor crcCur(22) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(31);
      retVar(7) := data(0) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(10) xor data(15) xor data(16) xor data(21) xor data(22) xor data(23) xor data(24) xor data(25) xor data(28) xor data(29) xor data(32) xor data(34) xor data(37) xor data(39) xor data(41) xor data(42) xor data(43) xor data(45) xor data(46) xor data(47) xor crcCur(0) xor crcCur(5) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(12) xor crcCur(13) xor crcCur(16) xor crcCur(18) xor crcCur(21) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(8) := data(0) xor data(1) xor data(3) xor data(4) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(22) xor data(23) xor data(28) xor data(31) xor data(32) xor data(33) xor data(34) xor data(35) xor data(37) xor data(38) xor data(40) xor data(42) xor data(43) xor data(45) xor data(46) xor crcCur(1) xor crcCur(6) xor crcCur(7) xor crcCur(12) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(30);
      retVar(9) := data(1) xor data(2) xor data(4) xor data(5) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(23) xor data(24) xor data(29) xor data(32) xor data(33) xor data(34) xor data(35) xor data(36) xor data(38) xor data(39) xor data(41) xor data(43) xor data(44) xor data(46) xor data(47) xor crcCur(2) xor crcCur(7) xor crcCur(8) xor crcCur(13) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(10) := data(0) xor data(2) xor data(3) xor data(5) xor data(9) xor data(13) xor data(14) xor data(16) xor data(19) xor data(26) xor data(28) xor data(29) xor data(31) xor data(32) xor data(33) xor data(35) xor data(36) xor data(39) xor data(40) xor data(42) xor crcCur(0) xor crcCur(3) xor crcCur(10) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(23) xor crcCur(24) xor crcCur(26);
      retVar(11) := data(0) xor data(1) xor data(3) xor data(4) xor data(9) xor data(12) xor data(14) xor data(15) xor data(16) xor data(17) xor data(20) xor data(24) xor data(25) xor data(26) xor data(27) xor data(28) xor data(31) xor data(33) xor data(36) xor data(40) xor data(41) xor data(43) xor data(44) xor data(45) xor data(47) xor crcCur(0) xor crcCur(1) xor crcCur(4) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(15) xor crcCur(17) xor crcCur(20) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(12) := data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(17) xor data(18) xor data(21) xor data(24) xor data(27) xor data(30) xor data(31) xor data(41) xor data(42) xor data(46) xor data(47) xor crcCur(1) xor crcCur(2) xor crcCur(5) xor crcCur(8) xor crcCur(11) xor crcCur(14) xor crcCur(15) xor crcCur(25) xor crcCur(26) xor crcCur(30) xor crcCur(31);
      retVar(13) := data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(18) xor data(19) xor data(22) xor data(25) xor data(28) xor data(31) xor data(32) xor data(42) xor data(43) xor data(47) xor crcCur(0) xor crcCur(2) xor crcCur(3) xor crcCur(6) xor crcCur(9) xor crcCur(12) xor crcCur(15) xor crcCur(16) xor crcCur(26) xor crcCur(27) xor crcCur(31);
      retVar(14) := data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(20) xor data(23) xor data(26) xor data(29) xor data(32) xor data(33) xor data(43) xor data(44) xor crcCur(1) xor crcCur(3) xor crcCur(4) xor crcCur(7) xor crcCur(10) xor crcCur(13) xor crcCur(16) xor crcCur(17) xor crcCur(27) xor crcCur(28);
      retVar(15) := data(3) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21) xor data(24) xor data(27) xor data(30) xor data(33) xor data(34) xor data(44) xor data(45) xor crcCur(0) xor crcCur(2) xor crcCur(4) xor crcCur(5) xor crcCur(8) xor crcCur(11) xor crcCur(14) xor crcCur(17) xor crcCur(18) xor crcCur(28) xor crcCur(29);
      retVar(16) := data(0) xor data(4) xor data(5) xor data(8) xor data(12) xor data(13) xor data(17) xor data(19) xor data(21) xor data(22) xor data(24) xor data(26) xor data(29) xor data(30) xor data(32) xor data(35) xor data(37) xor data(44) xor data(46) xor data(47) xor crcCur(1) xor crcCur(3) xor crcCur(5) xor crcCur(6) xor crcCur(8) xor crcCur(10) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(19) xor crcCur(21) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(17) := data(1) xor data(5) xor data(6) xor data(9) xor data(13) xor data(14) xor data(18) xor data(20) xor data(22) xor data(23) xor data(25) xor data(27) xor data(30) xor data(31) xor data(33) xor data(36) xor data(38) xor data(45) xor data(47) xor crcCur(2) xor crcCur(4) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(11) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(20) xor crcCur(22) xor crcCur(29) xor crcCur(31);
      retVar(18) := data(2) xor data(6) xor data(7) xor data(10) xor data(14) xor data(15) xor data(19) xor data(21) xor data(23) xor data(24) xor data(26) xor data(28) xor data(31) xor data(32) xor data(34) xor data(37) xor data(39) xor data(46) xor crcCur(3) xor crcCur(5) xor crcCur(7) xor crcCur(8) xor crcCur(10) xor crcCur(12) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(21) xor crcCur(23) xor crcCur(30);
      retVar(19) := data(3) xor data(7) xor data(8) xor data(11) xor data(15) xor data(16) xor data(20) xor data(22) xor data(24) xor data(25) xor data(27) xor data(29) xor data(32) xor data(33) xor data(35) xor data(38) xor data(40) xor data(47) xor crcCur(0) xor crcCur(4) xor crcCur(6) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(13) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(22) xor crcCur(24) xor crcCur(31);
      retVar(20) := data(4) xor data(8) xor data(9) xor data(12) xor data(16) xor data(17) xor data(21) xor data(23) xor data(25) xor data(26) xor data(28) xor data(30) xor data(33) xor data(34) xor data(36) xor data(39) xor data(41) xor crcCur(0) xor crcCur(1) xor crcCur(5) xor crcCur(7) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(14) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(23) xor crcCur(25);
      retVar(21) := data(5) xor data(9) xor data(10) xor data(13) xor data(17) xor data(18) xor data(22) xor data(24) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(37) xor data(40) xor data(42) xor crcCur(1) xor crcCur(2) xor crcCur(6) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(15) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(24) xor crcCur(26);
      retVar(22) := data(0) xor data(9) xor data(11) xor data(12) xor data(14) xor data(16) xor data(18) xor data(19) xor data(23) xor data(24) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(36) xor data(37) xor data(38) xor data(41) xor data(43) xor data(44) xor data(45) xor data(47) xor crcCur(0) xor crcCur(2) xor crcCur(3) xor crcCur(7) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(15) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(23) := data(0) xor data(1) xor data(6) xor data(9) xor data(13) xor data(15) xor data(16) xor data(17) xor data(19) xor data(20) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(36) xor data(38) xor data(39) xor data(42) xor data(46) xor data(47) xor crcCur(0) xor crcCur(1) xor crcCur(3) xor crcCur(4) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(15) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(26) xor crcCur(30) xor crcCur(31);
      retVar(24) := data(1) xor data(2) xor data(7) xor data(10) xor data(14) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(27) xor data(28) xor data(30) xor data(32) xor data(35) xor data(36) xor data(37) xor data(39) xor data(40) xor data(43) xor data(47) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(4) xor crcCur(5) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(16) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(27) xor crcCur(31);
      retVar(25) := data(2) xor data(3) xor data(8) xor data(11) xor data(15) xor data(17) xor data(18) xor data(19) xor data(21) xor data(22) xor data(28) xor data(29) xor data(31) xor data(33) xor data(36) xor data(37) xor data(38) xor data(40) xor data(41) xor data(44) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(6) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(17) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(25) xor crcCur(28);
      retVar(26) := data(0) xor data(3) xor data(4) xor data(6) xor data(10) xor data(18) xor data(19) xor data(20) xor data(22) xor data(23) xor data(24) xor data(25) xor data(26) xor data(28) xor data(31) xor data(38) xor data(39) xor data(41) xor data(42) xor data(44) xor data(47) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(15) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(31);
      retVar(27) := data(1) xor data(4) xor data(5) xor data(7) xor data(11) xor data(19) xor data(20) xor data(21) xor data(23) xor data(24) xor data(25) xor data(26) xor data(27) xor data(29) xor data(32) xor data(39) xor data(40) xor data(42) xor data(43) xor data(45) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(16) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(29);
      retVar(28) := data(2) xor data(5) xor data(6) xor data(8) xor data(12) xor data(20) xor data(21) xor data(22) xor data(24) xor data(25) xor data(26) xor data(27) xor data(28) xor data(30) xor data(33) xor data(40) xor data(41) xor data(43) xor data(44) xor data(46) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(17) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      retVar(29) := data(3) xor data(6) xor data(7) xor data(9) xor data(13) xor data(21) xor data(22) xor data(23) xor data(25) xor data(26) xor data(27) xor data(28) xor data(29) xor data(31) xor data(34) xor data(41) xor data(42) xor data(44) xor data(45) xor data(47) xor crcCur(5) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(18) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(30) := data(4) xor data(7) xor data(8) xor data(10) xor data(14) xor data(22) xor data(23) xor data(24) xor data(26) xor data(27) xor data(28) xor data(29) xor data(30) xor data(32) xor data(35) xor data(42) xor data(43) xor data(45) xor data(46) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(19) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(30);
      retVar(31) := data(5) xor data(8) xor data(9) xor data(11) xor data(15) xor data(23) xor data(24) xor data(25) xor data(27) xor data(28) xor data(29) xor data(30) xor data(31) xor data(33) xor data(36) xor data(43) xor data(44) xor data(46) xor data(47) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(20) xor crcCur(27) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      return retVar;      
   end function;   

   function crc32Parallel7Byte (crcCur : slv(31 downto 0); data : slv(55 downto 0)) return slv is
      variable retVar : slv(31 downto 0) := (others => '0');
   begin
      retVar(0) := data(0) xor data(6) xor data(9) xor data(10) xor data(12) xor data(16) xor data(24) xor data(25) xor data(26) xor data(28) xor data(29) xor data(30) xor data(31) xor data(32) xor data(34) xor data(37) xor data(44) xor data(45) xor data(47) xor data(48) xor data(50) xor data(53) xor data(54) xor data(55) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(10) xor crcCur(13) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(1) := data(0) xor data(1) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(16) xor data(17) xor data(24) xor data(27) xor data(28) xor data(33) xor data(34) xor data(35) xor data(37) xor data(38) xor data(44) xor data(46) xor data(47) xor data(49) xor data(50) xor data(51) xor data(53) xor crcCur(0) xor crcCur(3) xor crcCur(4) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(14) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(29);
      retVar(2) := data(0) xor data(1) xor data(2) xor data(6) xor data(7) xor data(8) xor data(9) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(24) xor data(26) xor data(30) xor data(31) xor data(32) xor data(35) xor data(36) xor data(37) xor data(38) xor data(39) xor data(44) xor data(51) xor data(52) xor data(53) xor data(55) xor crcCur(0) xor crcCur(2) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(20) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(3) := data(1) xor data(2) xor data(3) xor data(7) xor data(8) xor data(9) xor data(10) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(25) xor data(27) xor data(31) xor data(32) xor data(33) xor data(36) xor data(37) xor data(38) xor data(39) xor data(40) xor data(45) xor data(52) xor data(53) xor data(54) xor crcCur(1) xor crcCur(3) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(21) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      retVar(4) := data(0) xor data(2) xor data(3) xor data(4) xor data(6) xor data(8) xor data(11) xor data(12) xor data(15) xor data(18) xor data(19) xor data(20) xor data(24) xor data(25) xor data(29) xor data(30) xor data(31) xor data(33) xor data(38) xor data(39) xor data(40) xor data(41) xor data(44) xor data(45) xor data(46) xor data(47) xor data(48) xor data(50) xor crcCur(0) xor crcCur(1) xor crcCur(5) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(26);
      retVar(5) := data(0) xor data(1) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(19) xor data(20) xor data(21) xor data(24) xor data(28) xor data(29) xor data(37) xor data(39) xor data(40) xor data(41) xor data(42) xor data(44) xor data(46) xor data(49) xor data(50) xor data(51) xor data(53) xor data(54) xor data(55) xor crcCur(0) xor crcCur(4) xor crcCur(5) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(22) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(6) := data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(20) xor data(21) xor data(22) xor data(25) xor data(29) xor data(30) xor data(38) xor data(40) xor data(41) xor data(42) xor data(43) xor data(45) xor data(47) xor data(50) xor data(51) xor data(52) xor data(54) xor data(55) xor crcCur(1) xor crcCur(5) xor crcCur(6) xor crcCur(14) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(23) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(7) := data(0) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(10) xor data(15) xor data(16) xor data(21) xor data(22) xor data(23) xor data(24) xor data(25) xor data(28) xor data(29) xor data(32) xor data(34) xor data(37) xor data(39) xor data(41) xor data(42) xor data(43) xor data(45) xor data(46) xor data(47) xor data(50) xor data(51) xor data(52) xor data(54) xor crcCur(0) xor crcCur(1) xor crcCur(4) xor crcCur(5) xor crcCur(8) xor crcCur(10) xor crcCur(13) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      retVar(8) := data(0) xor data(1) xor data(3) xor data(4) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(22) xor data(23) xor data(28) xor data(31) xor data(32) xor data(33) xor data(34) xor data(35) xor data(37) xor data(38) xor data(40) xor data(42) xor data(43) xor data(45) xor data(46) xor data(50) xor data(51) xor data(52) xor data(54) xor crcCur(4) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(22) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      retVar(9) := data(1) xor data(2) xor data(4) xor data(5) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(23) xor data(24) xor data(29) xor data(32) xor data(33) xor data(34) xor data(35) xor data(36) xor data(38) xor data(39) xor data(41) xor data(43) xor data(44) xor data(46) xor data(47) xor data(51) xor data(52) xor data(53) xor data(55) xor crcCur(0) xor crcCur(5) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(10) := data(0) xor data(2) xor data(3) xor data(5) xor data(9) xor data(13) xor data(14) xor data(16) xor data(19) xor data(26) xor data(28) xor data(29) xor data(31) xor data(32) xor data(33) xor data(35) xor data(36) xor data(39) xor data(40) xor data(42) xor data(50) xor data(52) xor data(55) xor crcCur(2) xor crcCur(4) xor crcCur(5) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(26) xor crcCur(28) xor crcCur(31);
      retVar(11) := data(0) xor data(1) xor data(3) xor data(4) xor data(9) xor data(12) xor data(14) xor data(15) xor data(16) xor data(17) xor data(20) xor data(24) xor data(25) xor data(26) xor data(27) xor data(28) xor data(31) xor data(33) xor data(36) xor data(40) xor data(41) xor data(43) xor data(44) xor data(45) xor data(47) xor data(48) xor data(50) xor data(51) xor data(54) xor data(55) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(7) xor crcCur(9) xor crcCur(12) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(30) xor crcCur(31);
      retVar(12) := data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(17) xor data(18) xor data(21) xor data(24) xor data(27) xor data(30) xor data(31) xor data(41) xor data(42) xor data(46) xor data(47) xor data(49) xor data(50) xor data(51) xor data(52) xor data(53) xor data(54) xor crcCur(0) xor crcCur(3) xor crcCur(6) xor crcCur(7) xor crcCur(17) xor crcCur(18) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      retVar(13) := data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(18) xor data(19) xor data(22) xor data(25) xor data(28) xor data(31) xor data(32) xor data(42) xor data(43) xor data(47) xor data(48) xor data(50) xor data(51) xor data(52) xor data(53) xor data(54) xor data(55) xor crcCur(1) xor crcCur(4) xor crcCur(7) xor crcCur(8) xor crcCur(18) xor crcCur(19) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(14) := data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(20) xor data(23) xor data(26) xor data(29) xor data(32) xor data(33) xor data(43) xor data(44) xor data(48) xor data(49) xor data(51) xor data(52) xor data(53) xor data(54) xor data(55) xor crcCur(2) xor crcCur(5) xor crcCur(8) xor crcCur(9) xor crcCur(19) xor crcCur(20) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(15) := data(3) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21) xor data(24) xor data(27) xor data(30) xor data(33) xor data(34) xor data(44) xor data(45) xor data(49) xor data(50) xor data(52) xor data(53) xor data(54) xor data(55) xor crcCur(0) xor crcCur(3) xor crcCur(6) xor crcCur(9) xor crcCur(10) xor crcCur(20) xor crcCur(21) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(16) := data(0) xor data(4) xor data(5) xor data(8) xor data(12) xor data(13) xor data(17) xor data(19) xor data(21) xor data(22) xor data(24) xor data(26) xor data(29) xor data(30) xor data(32) xor data(35) xor data(37) xor data(44) xor data(46) xor data(47) xor data(48) xor data(51) xor crcCur(0) xor crcCur(2) xor crcCur(5) xor crcCur(6) xor crcCur(8) xor crcCur(11) xor crcCur(13) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(27);
      retVar(17) := data(1) xor data(5) xor data(6) xor data(9) xor data(13) xor data(14) xor data(18) xor data(20) xor data(22) xor data(23) xor data(25) xor data(27) xor data(30) xor data(31) xor data(33) xor data(36) xor data(38) xor data(45) xor data(47) xor data(48) xor data(49) xor data(52) xor crcCur(1) xor crcCur(3) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(12) xor crcCur(14) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(28);
      retVar(18) := data(2) xor data(6) xor data(7) xor data(10) xor data(14) xor data(15) xor data(19) xor data(21) xor data(23) xor data(24) xor data(26) xor data(28) xor data(31) xor data(32) xor data(34) xor data(37) xor data(39) xor data(46) xor data(48) xor data(49) xor data(50) xor data(53) xor crcCur(0) xor crcCur(2) xor crcCur(4) xor crcCur(7) xor crcCur(8) xor crcCur(10) xor crcCur(13) xor crcCur(15) xor crcCur(22) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(29);
      retVar(19) := data(3) xor data(7) xor data(8) xor data(11) xor data(15) xor data(16) xor data(20) xor data(22) xor data(24) xor data(25) xor data(27) xor data(29) xor data(32) xor data(33) xor data(35) xor data(38) xor data(40) xor data(47) xor data(49) xor data(50) xor data(51) xor data(54) xor crcCur(0) xor crcCur(1) xor crcCur(3) xor crcCur(5) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(14) xor crcCur(16) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(30);
      retVar(20) := data(4) xor data(8) xor data(9) xor data(12) xor data(16) xor data(17) xor data(21) xor data(23) xor data(25) xor data(26) xor data(28) xor data(30) xor data(33) xor data(34) xor data(36) xor data(39) xor data(41) xor data(48) xor data(50) xor data(51) xor data(52) xor data(55) xor crcCur(1) xor crcCur(2) xor crcCur(4) xor crcCur(6) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(15) xor crcCur(17) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(31);
      retVar(21) := data(5) xor data(9) xor data(10) xor data(13) xor data(17) xor data(18) xor data(22) xor data(24) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(37) xor data(40) xor data(42) xor data(49) xor data(51) xor data(52) xor data(53) xor crcCur(0) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(7) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(16) xor crcCur(18) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(29);
      retVar(22) := data(0) xor data(9) xor data(11) xor data(12) xor data(14) xor data(16) xor data(18) xor data(19) xor data(23) xor data(24) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(36) xor data(37) xor data(38) xor data(41) xor data(43) xor data(44) xor data(45) xor data(47) xor data(48) xor data(52) xor data(55) xor crcCur(0) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(7) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(28) xor crcCur(31);
      retVar(23) := data(0) xor data(1) xor data(6) xor data(9) xor data(13) xor data(15) xor data(16) xor data(17) xor data(19) xor data(20) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(36) xor data(38) xor data(39) xor data(42) xor data(46) xor data(47) xor data(49) xor data(50) xor data(54) xor data(55) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(7) xor crcCur(10) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(15) xor crcCur(18) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(30) xor crcCur(31);
      retVar(24) := data(1) xor data(2) xor data(7) xor data(10) xor data(14) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(27) xor data(28) xor data(30) xor data(32) xor data(35) xor data(36) xor data(37) xor data(39) xor data(40) xor data(43) xor data(47) xor data(48) xor data(50) xor data(51) xor data(55) xor crcCur(3) xor crcCur(4) xor crcCur(6) xor crcCur(8) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(19) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(31);
      retVar(25) := data(2) xor data(3) xor data(8) xor data(11) xor data(15) xor data(17) xor data(18) xor data(19) xor data(21) xor data(22) xor data(28) xor data(29) xor data(31) xor data(33) xor data(36) xor data(37) xor data(38) xor data(40) xor data(41) xor data(44) xor data(48) xor data(49) xor data(51) xor data(52) xor crcCur(4) xor crcCur(5) xor crcCur(7) xor crcCur(9) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(17) xor crcCur(20) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28);
      retVar(26) := data(0) xor data(3) xor data(4) xor data(6) xor data(10) xor data(18) xor data(19) xor data(20) xor data(22) xor data(23) xor data(24) xor data(25) xor data(26) xor data(28) xor data(31) xor data(38) xor data(39) xor data(41) xor data(42) xor data(44) xor data(47) xor data(48) xor data(49) xor data(52) xor data(54) xor data(55) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(4) xor crcCur(7) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(27) := data(1) xor data(4) xor data(5) xor data(7) xor data(11) xor data(19) xor data(20) xor data(21) xor data(23) xor data(24) xor data(25) xor data(26) xor data(27) xor data(29) xor data(32) xor data(39) xor data(40) xor data(42) xor data(43) xor data(45) xor data(48) xor data(49) xor data(50) xor data(53) xor data(55) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(8) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(29) xor crcCur(31);
      retVar(28) := data(2) xor data(5) xor data(6) xor data(8) xor data(12) xor data(20) xor data(21) xor data(22) xor data(24) xor data(25) xor data(26) xor data(27) xor data(28) xor data(30) xor data(33) xor data(40) xor data(41) xor data(43) xor data(44) xor data(46) xor data(49) xor data(50) xor data(51) xor data(54) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(6) xor crcCur(9) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(30);
      retVar(29) := data(3) xor data(6) xor data(7) xor data(9) xor data(13) xor data(21) xor data(22) xor data(23) xor data(25) xor data(26) xor data(27) xor data(28) xor data(29) xor data(31) xor data(34) xor data(41) xor data(42) xor data(44) xor data(45) xor data(47) xor data(50) xor data(51) xor data(52) xor data(55) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(7) xor crcCur(10) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(31);
      retVar(30) := data(4) xor data(7) xor data(8) xor data(10) xor data(14) xor data(22) xor data(23) xor data(24) xor data(26) xor data(27) xor data(28) xor data(29) xor data(30) xor data(32) xor data(35) xor data(42) xor data(43) xor data(45) xor data(46) xor data(48) xor data(51) xor data(52) xor data(53) xor crcCur(0) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(8) xor crcCur(11) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(27) xor crcCur(28) xor crcCur(29);
      retVar(31) := data(5) xor data(8) xor data(9) xor data(11) xor data(15) xor data(23) xor data(24) xor data(25) xor data(27) xor data(28) xor data(29) xor data(30) xor data(31) xor data(33) xor data(36) xor data(43) xor data(44) xor data(46) xor data(47) xor data(49) xor data(52) xor data(53) xor data(54) xor crcCur(0) xor crcCur(1) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(12) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      return retVar;      
   end function;   

   function crc32Parallel8Byte (crcCur : slv(31 downto 0); data : slv(63 downto 0)) return slv is
      variable retVar : slv(31 downto 0) := (others => '0');
   begin
      retVar(0) := data(0) xor data(6) xor data(9) xor data(10) xor data(12) xor data(16) xor data(24) xor data(25) xor data(26) xor data(28) xor data(29) xor data(30) xor data(31) xor data(32) xor data(34) xor data(37) xor data(44) xor data(45) xor data(47) xor data(48) xor data(50) xor data(53) xor data(54) xor data(55) xor data(58) xor data(60) xor data(61) xor data(63) xor crcCur(0) xor crcCur(2) xor crcCur(5) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(26) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(1) := data(0) xor data(1) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(16) xor data(17) xor data(24) xor data(27) xor data(28) xor data(33) xor data(34) xor data(35) xor data(37) xor data(38) xor data(44) xor data(46) xor data(47) xor data(49) xor data(50) xor data(51) xor data(53) xor data(56) xor data(58) xor data(59) xor data(60) xor data(62) xor data(63) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(6) xor crcCur(12) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(2) := data(0) xor data(1) xor data(2) xor data(6) xor data(7) xor data(8) xor data(9) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(24) xor data(26) xor data(30) xor data(31) xor data(32) xor data(35) xor data(36) xor data(37) xor data(38) xor data(39) xor data(44) xor data(51) xor data(52) xor data(53) xor data(55) xor data(57) xor data(58) xor data(59) xor crcCur(0) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(7) xor crcCur(12) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(27);
      retVar(3) := data(1) xor data(2) xor data(3) xor data(7) xor data(8) xor data(9) xor data(10) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(25) xor data(27) xor data(31) xor data(32) xor data(33) xor data(36) xor data(37) xor data(38) xor data(39) xor data(40) xor data(45) xor data(52) xor data(53) xor data(54) xor data(56) xor data(58) xor data(59) xor data(60) xor crcCur(0) xor crcCur(1) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(13) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(28);
      retVar(4) := data(0) xor data(2) xor data(3) xor data(4) xor data(6) xor data(8) xor data(11) xor data(12) xor data(15) xor data(18) xor data(19) xor data(20) xor data(24) xor data(25) xor data(29) xor data(30) xor data(31) xor data(33) xor data(38) xor data(39) xor data(40) xor data(41) xor data(44) xor data(45) xor data(46) xor data(47) xor data(48) xor data(50) xor data(57) xor data(58) xor data(59) xor data(63) xor crcCur(1) xor crcCur(6) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(12) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(25) xor crcCur(26) xor crcCur(27) xor crcCur(31);
      retVar(5) := data(0) xor data(1) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(19) xor data(20) xor data(21) xor data(24) xor data(28) xor data(29) xor data(37) xor data(39) xor data(40) xor data(41) xor data(42) xor data(44) xor data(46) xor data(49) xor data(50) xor data(51) xor data(53) xor data(54) xor data(55) xor data(59) xor data(61) xor data(63) xor crcCur(5) xor crcCur(7) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(14) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(27) xor crcCur(29) xor crcCur(31);
      retVar(6) := data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(20) xor data(21) xor data(22) xor data(25) xor data(29) xor data(30) xor data(38) xor data(40) xor data(41) xor data(42) xor data(43) xor data(45) xor data(47) xor data(50) xor data(51) xor data(52) xor data(54) xor data(55) xor data(56) xor data(60) xor data(62) xor crcCur(6) xor crcCur(8) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(15) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(28) xor crcCur(30);
      retVar(7) := data(0) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(10) xor data(15) xor data(16) xor data(21) xor data(22) xor data(23) xor data(24) xor data(25) xor data(28) xor data(29) xor data(32) xor data(34) xor data(37) xor data(39) xor data(41) xor data(42) xor data(43) xor data(45) xor data(46) xor data(47) xor data(50) xor data(51) xor data(52) xor data(54) xor data(56) xor data(57) xor data(58) xor data(60) xor crcCur(0) xor crcCur(2) xor crcCur(5) xor crcCur(7) xor crcCur(9) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(14) xor crcCur(15) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(28);
      retVar(8) := data(0) xor data(1) xor data(3) xor data(4) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(22) xor data(23) xor data(28) xor data(31) xor data(32) xor data(33) xor data(34) xor data(35) xor data(37) xor data(38) xor data(40) xor data(42) xor data(43) xor data(45) xor data(46) xor data(50) xor data(51) xor data(52) xor data(54) xor data(57) xor data(59) xor data(60) xor data(63) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(6) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(14) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(22) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(31);
      retVar(9) := data(1) xor data(2) xor data(4) xor data(5) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(23) xor data(24) xor data(29) xor data(32) xor data(33) xor data(34) xor data(35) xor data(36) xor data(38) xor data(39) xor data(41) xor data(43) xor data(44) xor data(46) xor data(47) xor data(51) xor data(52) xor data(53) xor data(55) xor data(58) xor data(60) xor data(61) xor crcCur(0) xor crcCur(1) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(15) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(23) xor crcCur(26) xor crcCur(28) xor crcCur(29);
      retVar(10) := data(0) xor data(2) xor data(3) xor data(5) xor data(9) xor data(13) xor data(14) xor data(16) xor data(19) xor data(26) xor data(28) xor data(29) xor data(31) xor data(32) xor data(33) xor data(35) xor data(36) xor data(39) xor data(40) xor data(42) xor data(50) xor data(52) xor data(55) xor data(56) xor data(58) xor data(59) xor data(60) xor data(62) xor data(63) xor crcCur(0) xor crcCur(1) xor crcCur(3) xor crcCur(4) xor crcCur(7) xor crcCur(8) xor crcCur(10) xor crcCur(18) xor crcCur(20) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(11) := data(0) xor data(1) xor data(3) xor data(4) xor data(9) xor data(12) xor data(14) xor data(15) xor data(16) xor data(17) xor data(20) xor data(24) xor data(25) xor data(26) xor data(27) xor data(28) xor data(31) xor data(33) xor data(36) xor data(40) xor data(41) xor data(43) xor data(44) xor data(45) xor data(47) xor data(48) xor data(50) xor data(51) xor data(54) xor data(55) xor data(56) xor data(57) xor data(58) xor data(59) xor crcCur(1) xor crcCur(4) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(27);
      retVar(12) := data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(17) xor data(18) xor data(21) xor data(24) xor data(27) xor data(30) xor data(31) xor data(41) xor data(42) xor data(46) xor data(47) xor data(49) xor data(50) xor data(51) xor data(52) xor data(53) xor data(54) xor data(56) xor data(57) xor data(59) xor data(61) xor data(63) xor crcCur(9) xor crcCur(10) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(29) xor crcCur(31);
      retVar(13) := data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(18) xor data(19) xor data(22) xor data(25) xor data(28) xor data(31) xor data(32) xor data(42) xor data(43) xor data(47) xor data(48) xor data(50) xor data(51) xor data(52) xor data(53) xor data(54) xor data(55) xor data(57) xor data(58) xor data(60) xor data(62) xor crcCur(0) xor crcCur(10) xor crcCur(11) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(30);
      retVar(14) := data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(20) xor data(23) xor data(26) xor data(29) xor data(32) xor data(33) xor data(43) xor data(44) xor data(48) xor data(49) xor data(51) xor data(52) xor data(53) xor data(54) xor data(55) xor data(56) xor data(58) xor data(59) xor data(61) xor data(63) xor crcCur(0) xor crcCur(1) xor crcCur(11) xor crcCur(12) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(31);
      retVar(15) := data(3) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21) xor data(24) xor data(27) xor data(30) xor data(33) xor data(34) xor data(44) xor data(45) xor data(49) xor data(50) xor data(52) xor data(53) xor data(54) xor data(55) xor data(56) xor data(57) xor data(59) xor data(60) xor data(62) xor crcCur(1) xor crcCur(2) xor crcCur(12) xor crcCur(13) xor crcCur(17) xor crcCur(18) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      retVar(16) := data(0) xor data(4) xor data(5) xor data(8) xor data(12) xor data(13) xor data(17) xor data(19) xor data(21) xor data(22) xor data(24) xor data(26) xor data(29) xor data(30) xor data(32) xor data(35) xor data(37) xor data(44) xor data(46) xor data(47) xor data(48) xor data(51) xor data(56) xor data(57) xor crcCur(0) xor crcCur(3) xor crcCur(5) xor crcCur(12) xor crcCur(14) xor crcCur(15) xor crcCur(16) xor crcCur(19) xor crcCur(24) xor crcCur(25);
      retVar(17) := data(1) xor data(5) xor data(6) xor data(9) xor data(13) xor data(14) xor data(18) xor data(20) xor data(22) xor data(23) xor data(25) xor data(27) xor data(30) xor data(31) xor data(33) xor data(36) xor data(38) xor data(45) xor data(47) xor data(48) xor data(49) xor data(52) xor data(57) xor data(58) xor crcCur(1) xor crcCur(4) xor crcCur(6) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(20) xor crcCur(25) xor crcCur(26);
      retVar(18) := data(2) xor data(6) xor data(7) xor data(10) xor data(14) xor data(15) xor data(19) xor data(21) xor data(23) xor data(24) xor data(26) xor data(28) xor data(31) xor data(32) xor data(34) xor data(37) xor data(39) xor data(46) xor data(48) xor data(49) xor data(50) xor data(53) xor data(58) xor data(59) xor crcCur(0) xor crcCur(2) xor crcCur(5) xor crcCur(7) xor crcCur(14) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(21) xor crcCur(26) xor crcCur(27);
      retVar(19) := data(3) xor data(7) xor data(8) xor data(11) xor data(15) xor data(16) xor data(20) xor data(22) xor data(24) xor data(25) xor data(27) xor data(29) xor data(32) xor data(33) xor data(35) xor data(38) xor data(40) xor data(47) xor data(49) xor data(50) xor data(51) xor data(54) xor data(59) xor data(60) xor crcCur(0) xor crcCur(1) xor crcCur(3) xor crcCur(6) xor crcCur(8) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(22) xor crcCur(27) xor crcCur(28);
      retVar(20) := data(4) xor data(8) xor data(9) xor data(12) xor data(16) xor data(17) xor data(21) xor data(23) xor data(25) xor data(26) xor data(28) xor data(30) xor data(33) xor data(34) xor data(36) xor data(39) xor data(41) xor data(48) xor data(50) xor data(51) xor data(52) xor data(55) xor data(60) xor data(61) xor crcCur(1) xor crcCur(2) xor crcCur(4) xor crcCur(7) xor crcCur(9) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(23) xor crcCur(28) xor crcCur(29);
      retVar(21) := data(5) xor data(9) xor data(10) xor data(13) xor data(17) xor data(18) xor data(22) xor data(24) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(37) xor data(40) xor data(42) xor data(49) xor data(51) xor data(52) xor data(53) xor data(56) xor data(61) xor data(62) xor crcCur(2) xor crcCur(3) xor crcCur(5) xor crcCur(8) xor crcCur(10) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(24) xor crcCur(29) xor crcCur(30);
      retVar(22) := data(0) xor data(9) xor data(11) xor data(12) xor data(14) xor data(16) xor data(18) xor data(19) xor data(23) xor data(24) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(36) xor data(37) xor data(38) xor data(41) xor data(43) xor data(44) xor data(45) xor data(47) xor data(48) xor data(52) xor data(55) xor data(57) xor data(58) xor data(60) xor data(61) xor data(62) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(16) xor crcCur(20) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      retVar(23) := data(0) xor data(1) xor data(6) xor data(9) xor data(13) xor data(15) xor data(16) xor data(17) xor data(19) xor data(20) xor data(26) xor data(27) xor data(29) xor data(31) xor data(34) xor data(35) xor data(36) xor data(38) xor data(39) xor data(42) xor data(46) xor data(47) xor data(49) xor data(50) xor data(54) xor data(55) xor data(56) xor data(59) xor data(60) xor data(62) xor crcCur(2) xor crcCur(3) xor crcCur(4) xor crcCur(6) xor crcCur(7) xor crcCur(10) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(18) xor crcCur(22) xor crcCur(23) xor crcCur(24) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      retVar(24) := data(1) xor data(2) xor data(7) xor data(10) xor data(14) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(27) xor data(28) xor data(30) xor data(32) xor data(35) xor data(36) xor data(37) xor data(39) xor data(40) xor data(43) xor data(47) xor data(48) xor data(50) xor data(51) xor data(55) xor data(56) xor data(57) xor data(60) xor data(61) xor data(63) xor crcCur(0) xor crcCur(3) xor crcCur(4) xor crcCur(5) xor crcCur(7) xor crcCur(8) xor crcCur(11) xor crcCur(15) xor crcCur(16) xor crcCur(18) xor crcCur(19) xor crcCur(23) xor crcCur(24) xor crcCur(25) xor crcCur(28) xor crcCur(29) xor crcCur(31);
      retVar(25) := data(2) xor data(3) xor data(8) xor data(11) xor data(15) xor data(17) xor data(18) xor data(19) xor data(21) xor data(22) xor data(28) xor data(29) xor data(31) xor data(33) xor data(36) xor data(37) xor data(38) xor data(40) xor data(41) xor data(44) xor data(48) xor data(49) xor data(51) xor data(52) xor data(56) xor data(57) xor data(58) xor data(61) xor data(62) xor crcCur(1) xor crcCur(4) xor crcCur(5) xor crcCur(6) xor crcCur(8) xor crcCur(9) xor crcCur(12) xor crcCur(16) xor crcCur(17) xor crcCur(19) xor crcCur(20) xor crcCur(24) xor crcCur(25) xor crcCur(26) xor crcCur(29) xor crcCur(30);
      retVar(26) := data(0) xor data(3) xor data(4) xor data(6) xor data(10) xor data(18) xor data(19) xor data(20) xor data(22) xor data(23) xor data(24) xor data(25) xor data(26) xor data(28) xor data(31) xor data(38) xor data(39) xor data(41) xor data(42) xor data(44) xor data(47) xor data(48) xor data(49) xor data(52) xor data(54) xor data(55) xor data(57) xor data(59) xor data(60) xor data(61) xor data(62) xor crcCur(6) xor crcCur(7) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(15) xor crcCur(16) xor crcCur(17) xor crcCur(20) xor crcCur(22) xor crcCur(23) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(29) xor crcCur(30);
      retVar(27) := data(1) xor data(4) xor data(5) xor data(7) xor data(11) xor data(19) xor data(20) xor data(21) xor data(23) xor data(24) xor data(25) xor data(26) xor data(27) xor data(29) xor data(32) xor data(39) xor data(40) xor data(42) xor data(43) xor data(45) xor data(48) xor data(49) xor data(50) xor data(53) xor data(55) xor data(56) xor data(58) xor data(60) xor data(61) xor data(62) xor data(63) xor crcCur(0) xor crcCur(7) xor crcCur(8) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(16) xor crcCur(17) xor crcCur(18) xor crcCur(21) xor crcCur(23) xor crcCur(24) xor crcCur(26) xor crcCur(28) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(28) := data(2) xor data(5) xor data(6) xor data(8) xor data(12) xor data(20) xor data(21) xor data(22) xor data(24) xor data(25) xor data(26) xor data(27) xor data(28) xor data(30) xor data(33) xor data(40) xor data(41) xor data(43) xor data(44) xor data(46) xor data(49) xor data(50) xor data(51) xor data(54) xor data(56) xor data(57) xor data(59) xor data(61) xor data(62) xor data(63) xor crcCur(1) xor crcCur(8) xor crcCur(9) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(17) xor crcCur(18) xor crcCur(19) xor crcCur(22) xor crcCur(24) xor crcCur(25) xor crcCur(27) xor crcCur(29) xor crcCur(30) xor crcCur(31);
      retVar(29) := data(3) xor data(6) xor data(7) xor data(9) xor data(13) xor data(21) xor data(22) xor data(23) xor data(25) xor data(26) xor data(27) xor data(28) xor data(29) xor data(31) xor data(34) xor data(41) xor data(42) xor data(44) xor data(45) xor data(47) xor data(50) xor data(51) xor data(52) xor data(55) xor data(57) xor data(58) xor data(60) xor data(62) xor data(63) xor crcCur(2) xor crcCur(9) xor crcCur(10) xor crcCur(12) xor crcCur(13) xor crcCur(15) xor crcCur(18) xor crcCur(19) xor crcCur(20) xor crcCur(23) xor crcCur(25) xor crcCur(26) xor crcCur(28) xor crcCur(30) xor crcCur(31);
      retVar(30) := data(4) xor data(7) xor data(8) xor data(10) xor data(14) xor data(22) xor data(23) xor data(24) xor data(26) xor data(27) xor data(28) xor data(29) xor data(30) xor data(32) xor data(35) xor data(42) xor data(43) xor data(45) xor data(46) xor data(48) xor data(51) xor data(52) xor data(53) xor data(56) xor data(58) xor data(59) xor data(61) xor data(63) xor crcCur(0) xor crcCur(3) xor crcCur(10) xor crcCur(11) xor crcCur(13) xor crcCur(14) xor crcCur(16) xor crcCur(19) xor crcCur(20) xor crcCur(21) xor crcCur(24) xor crcCur(26) xor crcCur(27) xor crcCur(29) xor crcCur(31);
      retVar(31) := data(5) xor data(8) xor data(9) xor data(11) xor data(15) xor data(23) xor data(24) xor data(25) xor data(27) xor data(28) xor data(29) xor data(30) xor data(31) xor data(33) xor data(36) xor data(43) xor data(44) xor data(46) xor data(47) xor data(49) xor data(52) xor data(53) xor data(54) xor data(57) xor data(59) xor data(60) xor data(62) xor crcCur(1) xor crcCur(4) xor crcCur(11) xor crcCur(12) xor crcCur(14) xor crcCur(15) xor crcCur(17) xor crcCur(20) xor crcCur(21) xor crcCur(22) xor crcCur(25) xor crcCur(27) xor crcCur(28) xor crcCur(30);
      return retVar;      
   end function;      

end package body CrcPkg;

----------------------------------
-- 32-bit CRC Implementation    --
-- Arbitrary number of bytes in --
----------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.UtilityPkg.all;
use work.CrcPkg.all;

entity Crc32 is
   generic (
      BYTE_WIDTH_G  : integer := 4;                           -- Maximum byte width (1-8 supported)
      CRC_INIT_G    : slv(31 downto 0) := x"FFFFFFFF";
      GATE_DELAY_G  : time := 0.5 ns
   );
   port (
      crcOut        :  out slv(31 downto 0);                  -- CRC output
      crcClk        : in   sl;                                -- system clock
      crcDataValid  : in   sl;                                -- indicate that new data arrived and CRC can be computed
      crcDataWidth  : in   slv(2 downto 0);                   -- indicate width in bytes minus 1, 0 - 1 byte, 1 - 2 bytes ... , 7 - 8 bytes
      crcIn         : in   slv((BYTE_WIDTH_G*8-1) downto 0);  -- input data for CRC calculation
      crcReset      : in   sl                                 -- initializes CRC logic to CRC_INIT_G
   );                               
end Crc32;

architecture rtl of Crc32 is

   type RegType is record
      crc            : slv(31 downto 0);
      data           : slv((BYTE_WIDTH_G*8-1) downto 0);
      valid          : sl;
      byteWidth      : slv(2 downto 0);
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      crc           => CRC_INIT_G,
      data          => (others => '0'),
      valid         => '0',
      byteWidth     => (others => '0')
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   assert (BYTE_WIDTH_G > 0 and BYTE_WIDTH_G <= 8) report "BYTE_WIDTH_G must be in the range [1,8]" severity failure;

   comb : process(crcIn,crcDataWidth,crcReset,crcDataValid,r)
      variable v       : RegType;
      variable prevCrc : slv(31 downto 0);
   begin
      v := r;

      v.byteWidth := crcDataWidth;
      v.valid     := crcDataValid;
      
      -- Transpose the input data
      for byte in (BYTE_WIDTH_G-1) downto 0 loop
         if (crcDataWidth >= BYTE_WIDTH_G-byte-1) then
            for b in 0 to 7 loop
               v.data((byte+1)*8-1-b) := crcIn(byte*8+b);
            end loop;
         else 
            v.data((byte+1)*8-1 downto byte*8) := (others => '0');
         end if;            
      end loop;

      if (crcReset = '0') then
         prevCrc := r.crc;
      else
         prevCrc := CRC_INIT_G;
      end if;      
      
      -- Calculate CRC in parallel - implementation used depends on the 
      -- byte width in use.      
      if (r.valid = '1') then
         case(r.byteWidth) is
            when "000" => 
               v.crc := crc32Parallel1Byte(prevCrc, r.data(BYTE_WIDTH_G*8-1 downto (BYTE_WIDTH_G-1)*8));
            when "001" => 
               if (BYTE_WIDTH_G >= 2) then
                  v.crc := crc32Parallel2Byte(prevCrc, r.data(BYTE_WIDTH_G*8-1 downto (BYTE_WIDTH_G-2)*8));
               end if;
            when "010" => 
               if (BYTE_WIDTH_G >= 3) then
                  v.crc := crc32Parallel3Byte(prevCrc, r.data(BYTE_WIDTH_G*8-1 downto (BYTE_WIDTH_G-3)*8));
               end if; 
            when "011" => 
               if (BYTE_WIDTH_G >= 4) then
                  v.crc := crc32Parallel4Byte(prevCrc, r.data(BYTE_WIDTH_G*8-1 downto (BYTE_WIDTH_G-4)*8));
               end if;
            when "100" => 
               if (BYTE_WIDTH_G >= 5) then
                  v.crc := crc32Parallel5Byte(prevCrc, r.data(BYTE_WIDTH_G*8-1 downto (BYTE_WIDTH_G-5)*8));
               end if;
            when "101" =>
               if (BYTE_WIDTH_G >= 6) then
                  v.crc := crc32Parallel6Byte(prevCrc, r.data(BYTE_WIDTH_G*8-1 downto (BYTE_WIDTH_G-6)*8));
               end if;
            when "110" => 
               if (BYTE_WIDTH_G >= 7) then            
                  v.crc := crc32Parallel7Byte(prevCrc, r.data(BYTE_WIDTH_G*8-1 downto (BYTE_WIDTH_G-7)*8));
               end if;
            when "111" => 
               if (BYTE_WIDTH_G = 8) then
                  v.crc := crc32Parallel8Byte(prevCrc, r.data(BYTE_WIDTH_G*8-1 downto (BYTE_WIDTH_G-8)*8));
               end if;
            when others => v.crc := (others => '0');
         end case;
      else
         v.crc := prevCrc;
      end if;
      
      rin <= v;

      -- Transpose each byte in the data out and invert
      -- This inversion is equivalent to an XOR of the CRC register with xFFFFFFFF 
      for byte in 0 to 3 loop
         for b in 0 to 7 loop
            crcOut(byte*8+b) <= not(r.crc((byte+1)*8-1-b)); 
         end loop;
      end loop;
     
   end process;

   seq : process (crcClk) is
   begin
      if (rising_edge(crcClk)) then
         r <= rin after GATE_DELAY_G;
      end if;
   end process seq;

end rtl;
