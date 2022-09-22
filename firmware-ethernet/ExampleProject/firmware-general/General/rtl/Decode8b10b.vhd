-- Translated to vhdl from verilog module decode_8b10b.v 
-- by Kurtis Nishimura, 2015
-- from source obtained at:
-- 
--   http://asics.chuckbenz.com/decode.v
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

entity Decode8b10b is 
   generic (
      GATE_DELAY_G   : time := 1 ns
   );
   port (
      clk      : in sl;
      clkEn    : in sl := '1';
      rst      : in sl := '0';
      dataIn   : in slv(9 downto 0);
      dispIn   : in sl;
      dataOut  : out slv(7 downto 0);
      dataKOut : out sl;
      dispOut  : out sl;
      codeErr  : out sl;
      dispErr  : out sl
   );
end Decode8b10b;

architecture rtl of Decode8b10b is 
   signal ai, bi, ci, di, ei, fi, gi, hi, ii, ji : sl;
   signal aeqb, ceqd, p22, p40, p04, p13, p31 : sl;
   signal disp6a, disp6a2, disp6a0, disp6b : sl;
   signal p22bceeqi, p22bncneeqi, p13in, p3li, p13dei : sl;
   signal p22aceeqi, p22ancneeqi, p13en, anbnenin : sl;
   signal abei, cdei, cndnenin : sl;
   signal p22enin, p22ei, p31dnenin, p31i, p31e : sl;
   signal compa, compb, compc, compd, compe : sl;
   signal ao, bo, co, do, eo : sl;
   signal feqg, heqj, fghj22, fghjp13, fghjp31, dispoutRaw : sl;
   signal ko, alt7, k28, k28p, fo, go, ho : sl;
   signal disp6p, disp6n, disp4p, disp4n : sl;
   signal code_err : sl; 
   signal disp_err : sl;
   signal dataOutRaw  : slv(7 downto 0);
   signal dataKOutRaw : sl;
begin

   -- Combinatorial logic
   ai <= dataIn(0);
   bi <= dataIn(1);
   ci <= dataIn(2);
   di <= dataIn(3);
   ei <= dataIn(4);
   ii <= dataIn(5);
   fi <= dataIn(6);
   gi <= dataIn(7);
   hi <= dataIn(8);
   ji <= dataIn(9);

   aeqb <= (ai and bi) or (not(ai) and not(bi));
   ceqd <= (ci and di) or (not(ci) and not(di));
   p22  <= (ai and bi and not(ci) and not(di)) or
           (ci and di and not(ai) and not(bi)) or
           (not(aeqb) and not(ceqd));
   p13  <= (not(aeqb) and not(ci) and not(di)) or
           (not(ceqd) and not(ai) and not(bi));
   p31  <= (not(aeqb) and ci and di) or
           (not(ceqd) and ai and bi);

   p40 <= ai and bi and ci and di;
   p04 <= not(ai) and not(bi) and not(ci) and not(di);

   disp6a  <= p31 or (p22 and dispin); -- pos disp if p22 and was pos, or p31.
   disp6a2 <= p31 and dispin;  -- disp is ++ after 4 bits
   disp6a0 <= p13 and not(dispin); -- -- disp after 4 bits
    
   disp6b <= (((ei and ii and not(disp6a0)) or (disp6a and (ei or ii)) or disp6a2 or
             (ei and ii and di)) and (ei or ii or di));

   -- The 5B/6B decoding special cases where ABCDE != abcde
   p22bceeqi <= p22 and bi and ci when (ei = ii) else '0';
   p22bncneeqi <= p22 and not(bi) and not(ci) when (ei = ii) else '0';
   p13in <= p13 and not(ii);
   p31i <= p31 and ii;
   p13dei <= p13 and di and ei and ii;
   p22aceeqi <= p22 and ai and ci when (ei = ii) else '0';
   p22ancneeqi <= p22 and not(ai) and not(ci) when (ei = ii) else '0';
   p13en <= p13 and not(ei);
   anbnenin <= not(ai) and not(bi) and not(ei) and not(ii);
   abei <= ai and bi and ei and ii;
   cdei <= ci and di and ei and ii;
   cndnenin <= not(ci) and not(di) and not(ei) and not(ii);

   -- non-zero disparity cases:
   p22enin <= p22 and not(ei) and not(ii);
   p22ei <= p22 and ei and ii;
   p31dnenin <= p31 and not(di) and not(ei) and not(ii);
   p31e <= p31 and ei;

   compa <= p22bncneeqi or p31i or p13dei or p22ancneeqi or 
            p13en or abei or cndnenin ;
   compb <= p22bceeqi or p31i or p13dei or p22aceeqi or 
            p13en or abei or cndnenin ;
   compc <= p22bceeqi or p31i or p13dei or p22ancneeqi or 
            p13en or anbnenin or cndnenin ;
   compd <= p22bncneeqi or p31i or p13dei or p22aceeqi or
            p13en or abei or cndnenin ;
   compe <= p22bncneeqi or p13in or p13dei or p22ancneeqi or 
            p13en or anbnenin or cndnenin ;

   ao <= ai xor compa;
   bo <= bi xor compb;
   co <= ci xor compc;
   do <= di xor compd;
   eo <= ei xor compe;

   feqg <= (fi and gi) or (not(fi) and not(gi));
   heqj <= (hi and ji) or (not(hi) and not(ji));
   fghj22 <= (fi and gi and not(hi) and not(ji)) or
             (not(fi) and not(gi) and hi and ji) or
             (not(feqg) and not(heqj));
   fghjp13 <= (not(feqg) and not(hi) and not(ji)) or
              (not(heqj) and not(fi) and not(gi));
   fghjp31 <= ( not(feqg) and hi and ji) or
              (not(heqj) and fi and gi);

   dispoutRaw <= (fghjp31 or (disp6b and fghj22) or (hi and ji)) and (hi or ji);

   ko <= ( (ci and di and ei and ii) or (not(ci) and not(di) and not(ei) and not(ii)) or
        (p13 and not(ei) and ii and gi and hi and ji) or
        (p31 and ei and not(ii) and not(gi) and not(hi) and not(ji)));

   alt7 <= (fi and not(gi) and not(hi) and -- 1000 cases, where disp6b is 1
           ((dispin and ci and di and not(ei) and not(ii)) or ko or
           (dispin and not(ci) and di and not(ei) and not(ii)))) or
           (not(fi) and gi and hi and -- 0111 cases, where disp6b is 0
           ((not(dispin) and not(ci) and not(di) and ei and ii) or ko or
           (not(dispin) and ci and not(di) and ei and ii)));

   k28 <= (ci and di and ei and ii) or not(ci or di or ei or ii);
   -- k28 with positive disp into fghi - .1, .2, .5, and .6 special cases
   k28p <= not(ci or di or ei or ii);
   fo <= (ji and not(fi) and (hi or not(gi) or k28p)) or
         (fi and not(ji) and (not(hi) or gi or not(k28p))) or
         (k28p and gi and hi) or
         (not(k28p) and not(gi) and not(hi));
   go <= (ji and not(fi) and (hi or not(gi) or not(k28p))) or
         (fi and not(ji) and (not(hi) or gi or k28p)) or
         (not(k28p) and gi and hi) or
         (k28p and not(gi) and not(hi));
   ho <= ((ji xor hi) and not((not(fi) and gi and not(hi) and ji and not(k28p)) or (not(fi) and gi and hi and not(ji) and k28p) or 
         (fi and not(gi) and not(hi) and ji and not(k28p)) or (fi and not(gi) and hi and not(ji) and k28p))) or
         (not(fi) and gi and hi and ji) or (fi and not(gi) and not(hi) and not(ji));

   disp6p <= (p31 and (ei or ii)) or (p22 and ei and ii);
   disp6n <= (p13 and not(ei and ii)) or (p22 and not(ei) and not(ii));
   disp4p <= fghjp31;
   disp4n <= fghjp13;

   code_err <= p40 or p04 or (fi and gi and hi and ji) or (not(fi) and not(gi) and not(hi) and not(ji)) or
          (p13 and not(ei) and not(ii)) or (p31 and ei and ii) or 
          (ei and ii and fi and gi and hi) or (not(ei) and not(ii) and not(fi) and not(gi) and not(hi)) or 
          (ei and not(ii) and gi and hi and ji) or (not(ei) and ii and not(gi) and not(hi) and not(ji)) or
          (not(p31) and ei and not(ii) and not(gi) and not(hi) and not(ji)) or
          (not(p13) and not(ei) and ii and gi and hi and ji) or
          (((ei and ii and not(gi) and not(hi) and not(ji)) or 
            (not(ei) and not(ii) and gi and hi and ji)) and
            not((ci and di and ei) or (not(ci) and not(di) and not(ei)))) or
          (disp6p and disp4p) or (disp6n and disp4n) or
          (ai and bi and ci and not(ei) and not(ii) and ((not(fi) and not(gi)) or fghjp13)) or
          (not(ai) and not(bi) and not(ci) and ei and ii and ((fi and gi) or fghjp31)) or
          (fi and gi and not(hi) and not(ji) and disp6p) or
          (not(fi) and not(gi) and hi and ji and disp6n) or
          (ci and di and ei and ii and not(fi) and not(gi) and not(hi)) or
          (not(ci) and not(di) and not(ei) and not(ii) and fi and gi and hi) ;

   dataKOutRaw <= ko;
   dataOutRaw(7) <= ho;
   dataOutRaw(6) <= go;
   dataOutRaw(5) <= fo;
   dataOutRaw(4) <= eo;
   dataOutRaw(3) <= do;
   dataOutRaw(2) <= co;
   dataOutRaw(1) <= bo;
   dataOutRaw(0) <= ao;

   -- my disp err fires for any legal codes that violate disparity, may fire for illegal codes
   disp_err <= ((dispin and disp6p) or (disp6n and not(dispin)) or
            (dispin and not(disp6n) and fi and gi) or
            (dispin and ai and bi and ci) or
            (dispin and not(disp6n) and disp4p) or
            (not(dispin) and not(disp6p) and not(fi) and not(gi)) or
            (not(dispin) and not(ai) and not(bi) and not(ci)) or
            (not(dispin) and not(disp6p) and disp4n) or
            (disp6p and disp4p) or (disp6n and disp4n)) ;
            
   process(clk) begin
      if rising_edge(clk) then
         if rst = '1' then
            dataOut  <= (others => '0');
            dataKOut <= '0';
            dispOut  <= '0';
            codeErr  <= '0';
            dispErr  <= '0';
         elsif clkEn = '1' then
            dataOut  <= dataOutRaw;
            dataKOut <= dataKOutRaw;
            dispOut  <= dispoutRaw;
            codeErr  <= code_err;
            dispErr  <= disp_err;
         end if;
      end if;
   end process;

end rtl;

