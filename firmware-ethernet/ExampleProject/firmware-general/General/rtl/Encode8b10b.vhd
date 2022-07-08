-- Translated to vhdl from verilog module encode_8b10b.v 
-- by Kurtis Nishimura, 2015
-- from source obtained at:
-- 
--   http://asics.chuckbenz.com/encode.v
--
-- Original copyright information:
-- // Chuck Benz, Hollis, NH   Copyright (c)2002
-- //
-- // The information and description contained herein is the
-- // property of Chuck Benz.
-- //
-- // Permission is granted for any reuse of this information
-- // and description as long as this copyright notice is
-- // preserved.  Modifications may be made as long as this
-- // notice is preserved.
-- 
-- // per Widmer and Franaszek
--
-- 

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.UtilityPkg.all;

entity Encode8b10b is 
   generic (
      GATE_DELAY_G   : time := 1 ns
   );
   port (
      clk     : in sl;
      clkEn   : in sl := '1';
      rst     : in sl := '0';
      dataIn  : in slv(7 downto 0);
      dataKIn : in sl;
      dispIn  : in sl;
      dataOut : out slv(9 downto 0);
      dispOut : out sl
   );
end Encode8b10b;

architecture rtl of Encode8b10b is 
   signal ai, bi, ci, di, ei, fi, gi, hi, ki  : sl;
   signal aeqb, ceqd, l22, l40, l04, l13, l31 : sl;
   signal ao, bo, co, do, eo, fo, go, ho, io, jo : sl;
   signal pds16, nds16 : sl;
   signal ndos6, pdos6 : sl;
   signal alt7 : sl;
   signal nd1s4, pd1s4 : sl;
   signal ndos4, pdos4 : sl;
   signal illegalk : sl;
   signal compls6, disp6, compls4 : sl;
   signal dispOutRaw : sl;
   signal dataOutRaw : slv(9 downto 0);

begin

   -- Rename variables to abcdefgh format
   ai <= dataIn(0);
   bi <= dataIn(1);
   ci <= dataIn(2);
   di <= dataIn(3);
   ei <= dataIn(4);
   fi <= dataIn(5);
   gi <= dataIn(6);
   hi <= dataIn(7);
   ki <= dataKIn;

   -- Combinatorial calculations
   aeqb <= (ai and bi) or ( not(ai) and not(bi) );
   ceqd <= (ci and di) or ( not(ci) and not(di) );
   l22  <= (ai and bi and not(ci) and not(di)) or 
           (ci and di and not(ai) and not(bi)) or 
           (not(aeqb) and not(ceqd));
   l40  <= ai and bi and ci and di;
   l04  <= not(ai) and not(bi) and not(ci) and not(di);
   l13  <= (not(aeqb) and not(ci) and not(di)) or
           (not(ceqd) and not(ai) and not(bi));
   l31  <= (not(aeqb) and ci and di) or
           (not(ceqd) and ai and bi);
   -- 5B/6B encoding
   ao   <= ai;
   bo   <= (bi and not(l40)) or (l04);
   co   <= l04 or ci or (ei and di and not(ci) and not(bi) and not(ai));
   do   <= di and not(ai and bi and ci);
   eo   <= (ei or l13) and not( ei and di and not(ci) and not(bi) and not(ai) );
   io   <= (l22 and not(ei)) or
           (ei and not(di) and not(ci) and not(ai and bi)) or  -- D16, D17, D18
           (ei and l40) or
           (ki and ei and di and ci and not(bi) and not(ai)) or -- K.28
           (ei and not(di) and ci and not(bi) and not(ai));
   -- pds16 indicates cases where d-1 is assumed + to get our encoded value
   pds16 <= (ei and di and not(ci) and not(bi) and not(ai)) or (not(ei) and not(l22) and not(l31));
   -- nds16 indicates cases where d-1 is assumed - to get our encoded value
   nds16 <= ki or
            (ei and not(l22) and not(l13)) or
            (not(ei) and not(di) and ci and bi and ai);
   -- ndos6 is pds16 cases where d-1 is + yields - disp out - all of them
   ndos6 <= pds16 ;
   -- pdos6 is nds16 cases where d-1 is - yields + disp out - all but one
   pdos6 <= ki or 
            (ei and not(l22) and not(l13));
   -- some Dx.7 and all Kx.7 cases result in run length of 5 case unless
   -- an alternate coding is used (referred to as Dx.A7, normal is Dx.P7)
   -- specifically, D11, D13, D14, D17, D18, D19.
   alt7 <= fi and gi and hi and (ki or (not(ei) and di and l31)) when dispIn = '1' else
           fi and gi and hi and (ki or (ei and not(di) and l13));


   fo <= fi and not(alt7);
   go <= gi or (not(fi) and not(gi) and not(hi));
   ho <= hi;
   jo <= (not(hi) and(gi xor fi)) or alt7;

   -- nd1s4 is cases where d-1 is assumed - to get our encoded value
   nd1s4 <= fi and gi;
   -- pd1s4 is cases where d-1 is assumed + to get our encoded value
   pd1s4 <= (not(fi) and not(gi)) or (ki and ((fi and not(gi)) or (not(fi) and gi)));

   -- ndos4 is pd1s4 cases where d-1 is + yields - disp out - just some
   ndos4 <= (not(fi) and not(gi));
   -- pdos4 is nd1s4 cases where d-1 is - yields + disp out 
   pdos4 <= fi and gi and hi;

   -- only legal K codes are K28.0->.7, K23/27/29/30.7
   --  K28.0->7 is ei=di=ci=1,bi=ai=0
   --  K23 is 10111
   --  K27 is 11011
   --  K29 is 11101
   --  K30 is 11110 - so K23/27/29/30 are ei & l31
   illegalk <= ki and 
               (ai or bi or not(ci) or not(ei)) and -- Not K28.0->7
               (not(fi) or not(gi) or not(hi) or not(ei) or not(l31)); -- Not K23/27/29/30.7

   -- now determine whether to do the complementing
   -- complement if prev disp is - and pds16 is set, or + and nds16 is set
   compls6 <= (pds16 and not(dispin)) or (nds16 and dispin);

   -- disparity out of 5b6b is disp in with pdso6 and ndso6
   -- pds16 indicates cases where d-1 is assumed + to get our encoded value
   -- ndos6 is cases where d-1 is + yields - disp out
   -- nds16 indicates cases where d-1 is assumed - to get our encoded value
   -- pdos6 is cases where d-1 is - yields + disp out
   -- disp toggles in all ndis16 cases, and all but that 1 nds16 case
   disp6 <= dispin xor (ndos6 or pdos6);
   
   compls4 <= (pd1s4 and not(disp6)) or (nd1s4 and disp6);

   -- Assign disparity and data out
   dispOutRaw <= disp6 xor (ndos4 or pdos4);
   -- Is the bit order right here?
   dataOutRaw(9) <= jo xor compls4;
   dataOutRaw(8) <= ho xor compls4;
   dataOutRaw(7) <= go xor compls4;
   dataOutRaw(6) <= fo xor compls4;
   dataOutRaw(5) <= io xor compls6;
   dataOutRaw(4) <= eo xor compls6;
   dataOutRaw(3) <= do xor compls6;
   dataOutRaw(2) <= co xor compls6;
   dataOutRaw(1) <= bo xor compls6;
   dataOutRaw(0) <= ao xor compls6;

   process(clk) begin
      if rising_edge(clk) then
         if rst = '1' then
            dataOut <= (others => '0');
            dispOut <= '0';
         elsif clkEn = '1' then
            dataOut <= dataOutRaw;
            dispOut <= dispOutRaw;
         end if;
      end if;
   end process;

end rtl;

