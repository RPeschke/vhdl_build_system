library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  use work.UtilityPkg.all;

  use work.axiStreamHelper.all; 

  package axiDWORDbi_p is
subtype  DWORD_data_t is DWORD;
constant DWORD_data_t_null : DWORD := (others => '0'); 
procedure resetData(data : inout DWORD_data_t);


type AxiToMaster_axiDWordBi is record 
TX_Ready : AxiDataReady_t; 
RX_ctrl : AxiCtrl; 
RX_Data : DWORD_data_t; 

end record AxiToMaster_axiDWordBi; 

constant  AxiToMaster_axiDWordBi_null: AxiToMaster_axiDWordBi := (TX_Ready => AxiDataReady_t_null,
RX_ctrl => AxiCtrl_null,
RX_Data => DWORD_data_t_null);


type AxiFromMaster_axiDWordBi is record 
TX_ctrl : AxiCtrl; 
TX_Data : DWORD_data_t; 
RX_Ready : AxiDataReady_t; 

end record AxiFromMaster_axiDWordBi; 

constant  AxiFromMaster_axiDWordBi_null: AxiFromMaster_axiDWordBi := (TX_ctrl => AxiCtrl_null,
TX_Data => DWORD_data_t_null,
RX_Ready => AxiDataReady_t_null);



-- Starting Pseudo class axiDWordBi_fromMaster
 
type axiDWordBi_fromMaster is record 
ctrl : AxiCtrl; 
data : DWORD_data_t; 
Ready : AxiDataReady_t; 
Ready0 : AxiDataReady_t; 
Ready1 : AxiDataReady_t; 
position : size_t; 

end record axiDWordBi_fromMaster; 

constant  axiDWordBi_fromMaster_null: axiDWordBi_fromMaster := (ctrl => AxiCtrl_null,
data => DWORD_data_t_null,
Ready => AxiDataReady_t_null,
Ready0 => AxiDataReady_t_null,
Ready1 => AxiDataReady_t_null,
position => size_t_null);

 procedure resetSender(this : inout axiDWordBi_fromMaster);
 procedure pullSender(this : inout axiDWordBi_fromMaster; tx_ready : in AxiDataReady_t);
 procedure pushSender(this : inout axiDWordBi_fromMaster; signal TX_Data : out DWORD_data_t; signal DataLast: out sl; signal DataValid: out sl);
 procedure IncrementPosSender(this : inout axiDWordBi_fromMaster);
 procedure ResetReceiver(this : inout axiDWordBi_fromMaster);
 procedure pullReceiver(this : inout axiDWordBi_fromMaster; RX_Data : in DWORD_data_t; DataLast : in sl; DataValid : in sl);
 procedure pushReceiver(this : inout axiDWordBi_fromMaster; signal RX_Ready : out AxiDataReady_t);
 procedure IncrementPosReceiver(this : inout axiDWordBi_fromMaster);
 function  IsReady(this :  axiDWordBi_fromMaster) return boolean;
 function  wasReady(this :  axiDWordBi_fromMaster) return boolean;
 function  IsValid(this :  axiDWordBi_fromMaster) return boolean;
 function  isLast(this :  axiDWordBi_fromMaster) return boolean;
 procedure SetValid(this : inout axiDWordBi_fromMaster; valid : in sl := '1');
 procedure SetLast(this : inout axiDWordBi_fromMaster; last : in sl := '1');
 procedure SetData(this : inout axiDWordBi_fromMaster; data : in DWORD_data_t);
 -- End Pseudo class axiDWordBi_fromMaster



-- Starting Pseudo class axiDWordBi_ToMaster
 
type axiDWordBi_ToMaster is record 
ctrl : AxiCtrl; 
data : DWORD_data_t; 
Ready : AxiDataReady_t; 
Ready0 : AxiDataReady_t; 
Ready1 : AxiDataReady_t; 
position : size_t; 

end record axiDWordBi_ToMaster; 

constant  axiDWordBi_ToMaster_null: axiDWordBi_ToMaster := (ctrl => AxiCtrl_null,
data => DWORD_data_t_null,
Ready => AxiDataReady_t_null,
Ready0 => AxiDataReady_t_null,
Ready1 => AxiDataReady_t_null,
position => size_t_null);

 procedure resetSender(this : inout axiDWordBi_ToMaster);
 procedure pullSender(this : inout axiDWordBi_ToMaster; tx_ready : in AxiDataReady_t);
 procedure pushSender(this : inout axiDWordBi_ToMaster; signal TX_Data : out DWORD_data_t; signal DataLast: out sl; signal DataValid: out sl);
 procedure IncrementPosSender(this : inout axiDWordBi_ToMaster);
 procedure ResetReceiver(this : inout axiDWordBi_ToMaster);
 procedure pullReceiver(this : inout axiDWordBi_ToMaster; RX_Data : in DWORD_data_t; DataLast : in sl; DataValid : in sl);
 procedure pushReceiver(this : inout axiDWordBi_ToMaster; signal RX_Ready : out AxiDataReady_t);
 procedure IncrementPosReceiver(this : inout axiDWordBi_ToMaster);
 function  IsReady(this :  axiDWordBi_ToMaster) return boolean;
 function  wasReady(this :  axiDWordBi_ToMaster) return boolean;
 function  IsValid(this :  axiDWordBi_ToMaster) return boolean;
 function  isLast(this :  axiDWordBi_ToMaster) return boolean;
 procedure SetValid(this : inout axiDWordBi_ToMaster; valid : in sl := '1');
 procedure SetLast(this : inout axiDWordBi_ToMaster; last : in sl := '1');
 procedure SetData(this : inout axiDWordBi_ToMaster; data : in DWORD_data_t);
 -- End Pseudo class axiDWordBi_ToMaster



-- Starting Pseudo class AxiRXTXMaster_axiDWordBi
 
type AxiRXTXMaster_axiDWordBi is record 
tx : axiDWordBi_fromMaster; 
rx : axiDWordBi_ToMaster; 

end record AxiRXTXMaster_axiDWordBi; 

constant  AxiRXTXMaster_axiDWordBi_null: AxiRXTXMaster_axiDWordBi := (tx => axiDWordBi_fromMaster_null,
rx => axiDWordBi_ToMaster_null);

 procedure AxiPullData(this : inout AxiRXTXMaster_axiDWordBi; signal tMaster : in AxiToMaster_axiDWordBi);
 procedure AxiPushData(this : inout AxiRXTXMaster_axiDWordBi; signal fromMaster : out AxiFromMaster_axiDWordBi);
 procedure AxiPullData(this : inout AxiRXTXMaster_axiDWordBi; signal tx_ready : in sl; signal RX_Data: in DWORD_data_t; signal RX_DataValid: in sl; signal RX_DataLast: in sl);
 procedure AxiPushData(this : inout AxiRXTXMaster_axiDWordBi; signal RX_Ready : out sl; signal TX_Data : out DWORD_data_t; signal TX_DataValid : out sl; signal TX_DataLast : out sl);
 function  txIsReady(this : AxiRXTXMaster_axiDWordBi) return boolean;
 procedure txSetData(this : inout AxiRXTXMaster_axiDWordBi; data : in DWORD_data_t);
 procedure txSetLast(this : inout AxiRXTXMaster_axiDWordBi);
 function  txIsLast(this :  AxiRXTXMaster_axiDWordBi) return boolean;
 function  txIsValid(this :  AxiRXTXMaster_axiDWordBi) return boolean;
 function  txGetData(this :  AxiRXTXMaster_axiDWordBi) return DWORD_data_t;
 function  txGetPos(this :  AxiRXTXMaster_axiDWordBi) return size_t;
 function  rxIsValidAndReady(this : AxiRXTXMaster_axiDWordBi) return boolean;
 function  rxGetData(this :  AxiRXTXMaster_axiDWordBi) return DWORD_data_t;
 procedure rxSetReady(this : inout AxiRXTXMaster_axiDWordBi);
 function  rxGetPos(this :  AxiRXTXMaster_axiDWordBi) return size_t;
 function  rxIsLast(this :  AxiRXTXMaster_axiDWordBi) return boolean;
 -- End Pseudo class AxiRXTXMaster_axiDWordBi



-- Starting Pseudo class AxiRXTXSlave_axiDWordBi
 
type AxiRXTXSlave_axiDWordBi is record 
tx : axiDWordBi_ToMaster; 
rx : axiDWordBi_fromMaster; 

end record AxiRXTXSlave_axiDWordBi; 

constant  AxiRXTXSlave_axiDWordBi_null: AxiRXTXSlave_axiDWordBi := (tx => axiDWordBi_ToMaster_null,
rx => axiDWordBi_fromMaster_null);

 procedure AxiPullData(this : inout AxiRXTXSlave_axiDWordBi; signal fMaster : in AxiFromMaster_axiDWordBi);
 procedure AxiPushData(this : inout AxiRXTXSlave_axiDWordBi; signal toMaster : out AxiToMaster_axiDWordBi);
 procedure AxiPullData(this : inout AxiRXTXSlave_axiDWordBi; signal RX_Ready : in sl; signal TX_Data : in DWORD_data_t; signal TXDataValid : in sl; signal TXDataLast : in sl);
 procedure AxiPushData(this : inout AxiRXTXSlave_axiDWordBi; signal TX_Ready : out sl; signal RX_Data : out DWORD_data_t; signal RX_DataValid : out sl;  signal RX_DataLast : out sl);
 function  txIsReady(this :  AxiRXTXSlave_axiDWordBi) return boolean;
 procedure txSetData(this : inout AxiRXTXSlave_axiDWordBi; data : in DWORD_data_t);
 procedure txSetLast(this : inout AxiRXTXSlave_axiDWordBi);
 function  txIsLast(this :  AxiRXTXSlave_axiDWordBi) return boolean;
 function  txIsValid(this :  AxiRXTXSlave_axiDWordBi) return boolean;
 function  txGetData(this :  AxiRXTXSlave_axiDWordBi) return DWORD_data_t;
 function  txGetPos(this :  AxiRXTXSlave_axiDWordBi) return size_t;
 function  rxIsValidAndReady(this :  AxiRXTXSlave_axiDWordBi) return boolean;
 function  rxGetData(this :  AxiRXTXSlave_axiDWordBi) return DWORD_data_t;
 procedure rxSetReady(this : inout AxiRXTXSlave_axiDWordBi);
 function  rxGetPos(this :  AxiRXTXSlave_axiDWordBi) return size_t;
 function  rxIsLast(this :  AxiRXTXSlave_axiDWordBi) return boolean;
 -- End Pseudo class AxiRXTXSlave_axiDWordBi

end axiDWORDbi_p;


package body axiDWORDbi_p is
procedure resetData(data : inout DWORD_data_t) is begin 
data := (others => '0'); 
end procedure resetData; 



-- Starting Pseudo class axiDWordBi_fromMaster
  procedure resetSender(this : inout axiDWordBi_fromMaster) is begin 

            resetData(this.Data);
            this.ctrl.DataLast  := '0';
            this.ctrl.DataValid := '0';
          
end procedure resetSender; 

 procedure pullSender(this : inout axiDWordBi_fromMaster; tx_ready : in AxiDataReady_t) is begin 

            this.Ready1 := this.Ready0;   
            this.Ready0 := this.Ready;
  	        this.ready :=tx_ready;
            resetSender(this);
          
end procedure pullSender; 

 procedure pushSender(this : inout axiDWordBi_fromMaster; signal TX_Data : out DWORD_data_t; signal DataLast: out sl; signal DataValid: out sl) is begin 

            TX_Data  <= this.Data after 1 ns;
            DataLast <= this.ctrl.DataLast after 1 ns;
            DataValid <= this.ctrl.DataValid after 1 ns;
            IncrementPosSender(this);
          
end procedure pushSender; 

 procedure IncrementPosSender(this : inout axiDWordBi_fromMaster) is begin 

            if IsValid(this) and IsReady(this) then 
              this.position := this.position + 1;
              if isLast(this) then
                this.position := 0;
              end if;
            end if;
          
end procedure IncrementPosSender; 

 procedure ResetReceiver(this : inout axiDWordBi_fromMaster) is begin 

            this.Ready    := '0';
            
           
end procedure ResetReceiver; 

 procedure pullReceiver(this : inout axiDWordBi_fromMaster; RX_Data : in DWORD_data_t; DataLast : in sl; DataValid : in sl) is begin 

            this.Ready1 := this.Ready0;
            this.Ready0 := this.Ready;
            this.Data  := RX_Data;
            this.ctrl.DataLast  := DataLast;
            this.ctrl.DataValid := DataValid;

            ResetReceiver(this);
           
end procedure pullReceiver; 

 procedure pushReceiver(this : inout axiDWordBi_fromMaster; signal RX_Ready : out AxiDataReady_t) is begin 

            RX_Ready <= this.Ready after 1 ns;
            IncrementPosReceiver(this);
           
end procedure pushReceiver; 

 procedure IncrementPosReceiver(this : inout axiDWordBi_fromMaster) is begin 

             if IsValid(this) and  wasReady(this) then 
                this.position := this.position + 1;
                if isLast(this) then
                    this.position := 0;
                end if;
             end if;
           
end procedure IncrementPosReceiver; 

 function  IsReady(this :  axiDWordBi_fromMaster) return boolean is begin 

             return this.Ready = '1';
           
end function IsReady; 

 function  wasReady(this :  axiDWordBi_fromMaster) return boolean is begin 

            return this.Ready1 = '1';
           
end function wasReady; 

 function  IsValid(this :  axiDWordBi_fromMaster) return boolean is begin 

             return this.ctrl.DataValid = '1';
           
end function IsValid; 

 function  isLast(this :  axiDWordBi_fromMaster) return boolean is begin 

            return this.ctrl.DataLast = '1';
           
end function isLast; 

 procedure SetValid(this : inout axiDWordBi_fromMaster; valid : in sl := '1') is begin 

            if not IsReady(this) then 
                report "Error receiver not ready";
            end if;
            this.ctrl.DataValid := valid;
           
end procedure SetValid; 

 procedure SetLast(this : inout axiDWordBi_fromMaster; last : in sl := '1') is begin 

            if not IsValid(this) then 
                report "Error data not set";
            end if;
            this.ctrl.DataLast := last;
          
end procedure SetLast; 

 procedure SetData(this : inout axiDWordBi_fromMaster; data : in DWORD_data_t) is begin 

            if not IsReady(this) then 
                report "Error slave is not ready";
            end if;
            if IsValid(this) then 
                report "Error data already set";
            end if;
            this.Data := data;
            SetValid(this);
          
end procedure SetData; 

 -- End Pseudo class axiDWordBi_fromMaster



-- Starting Pseudo class axiDWordBi_ToMaster
  procedure resetSender(this : inout axiDWordBi_ToMaster) is begin 

            resetData(this.Data);
            this.ctrl.DataLast  := '0';
            this.ctrl.DataValid := '0';
          
end procedure resetSender; 

 procedure pullSender(this : inout axiDWordBi_ToMaster; tx_ready : in AxiDataReady_t) is begin 

            this.Ready1 := this.Ready0;   
            this.Ready0 := this.Ready;
  	        this.ready :=tx_ready;
            resetSender(this);
          
end procedure pullSender; 

 procedure pushSender(this : inout axiDWordBi_ToMaster; signal TX_Data : out DWORD_data_t; signal DataLast: out sl; signal DataValid: out sl) is begin 

            TX_Data  <= this.Data after 1 ns;
            DataLast <= this.ctrl.DataLast after 1 ns;
            DataValid <= this.ctrl.DataValid after 1 ns;
            IncrementPosSender(this);
          
end procedure pushSender; 

 procedure IncrementPosSender(this : inout axiDWordBi_ToMaster) is begin 

            if IsValid(this) and IsReady(this) then 
              this.position := this.position + 1;
              if isLast(this) then
                this.position := 0;
              end if;
            end if;
          
end procedure IncrementPosSender; 

 procedure ResetReceiver(this : inout axiDWordBi_ToMaster) is begin 

            this.Ready    := '0';
            
           
end procedure ResetReceiver; 

 procedure pullReceiver(this : inout axiDWordBi_ToMaster; RX_Data : in DWORD_data_t; DataLast : in sl; DataValid : in sl) is begin 

            this.Ready1 := this.Ready0;
            this.Ready0 := this.Ready;
            this.Data  := RX_Data;
            this.ctrl.DataLast  := DataLast;
            this.ctrl.DataValid := DataValid;

            ResetReceiver(this);
           
end procedure pullReceiver; 

 procedure pushReceiver(this : inout axiDWordBi_ToMaster; signal RX_Ready : out AxiDataReady_t) is begin 

            RX_Ready <= this.Ready after 1 ns;
            IncrementPosReceiver(this);
           
end procedure pushReceiver; 

 procedure IncrementPosReceiver(this : inout axiDWordBi_ToMaster) is begin 

             if IsValid(this) and  wasReady(this) then 
                this.position := this.position + 1;
                if isLast(this) then
                    this.position := 0;
                end if;
             end if;
           
end procedure IncrementPosReceiver; 

 function  IsReady(this : axiDWordBi_ToMaster) return boolean is begin 

             return this.Ready = '1';
           
end function IsReady; 

 function  wasReady(this :  axiDWordBi_ToMaster) return boolean is begin 

            return this.Ready1 = '1';
           
end function wasReady; 

 function  IsValid(this :  axiDWordBi_ToMaster) return boolean is begin 

             return this.ctrl.DataValid = '1';
           
end function IsValid; 

 function  isLast(this :  axiDWordBi_ToMaster) return boolean is begin 

            return this.ctrl.DataLast = '1';
           
end function isLast; 

 procedure SetValid(this : inout axiDWordBi_ToMaster; valid : in sl := '1') is begin 

            if not IsReady(this) then 
                report "Error receiver not ready";
            end if;
            this.ctrl.DataValid := valid;
           
end procedure SetValid; 

 procedure SetLast(this : inout axiDWordBi_ToMaster; last : in sl := '1') is begin 

            if not IsValid(this) then 
                report "Error data not set";
            end if;
            this.ctrl.DataLast := last;
          
end procedure SetLast; 

 procedure SetData(this : inout axiDWordBi_ToMaster; data : in DWORD_data_t) is begin 

            if not IsReady(this) then 
                report "Error slave is not ready";
            end if;
            if IsValid(this) then 
                report "Error data already set";
            end if;
            this.Data := data;
            SetValid(this);
          
end procedure SetData; 

 -- End Pseudo class axiDWordBi_ToMaster



-- Starting Pseudo class AxiRXTXMaster_axiDWordBi
  procedure AxiPullData(this : inout AxiRXTXMaster_axiDWordBi; signal tMaster : in AxiToMaster_axiDWordBi) is begin 

            pullSender(this.tx, tMaster.tx_ready);
            pullReceiver(this.rx, tMaster.RX_Data ,tMaster.RX_ctrl.DataLast,  tMaster.RX_ctrl.DataValid);

           
end procedure AxiPullData; 

 procedure AxiPushData(this : inout AxiRXTXMaster_axiDWordBi; signal fromMaster : out AxiFromMaster_axiDWordBi) is begin 

            pushSender(this.tx, fromMaster.TX_Data ,fromMaster.TX_ctrl.DataLast,fromMaster.TX_ctrl.DataValid );
            pushReceiver(this.rx, fromMaster.RX_Ready);
           
end procedure AxiPushData; 

 procedure AxiPullData(this : inout AxiRXTXMaster_axiDWordBi; signal tx_ready : in sl; signal RX_Data: in DWORD_data_t; signal RX_DataValid: in sl; signal RX_DataLast: in sl) is begin 

            pullSender(this.tx, tx_ready);
            pullReceiver(this.rx, RX_Data , RX_DataLast,  RX_DataValid);

           
end procedure AxiPullData; 

 procedure AxiPushData(this : inout AxiRXTXMaster_axiDWordBi; signal RX_Ready : out sl; signal TX_Data : out DWORD_data_t; signal TX_DataValid : out sl; signal TX_DataLast : out sl) is begin 

            pushSender(this.tx, TX_Data, TX_DataLast ,TX_DataValid );
            pushReceiver(this.rx, RX_Ready);
           
end procedure AxiPushData; 

 function  txIsReady(this : AxiRXTXMaster_axiDWordBi) return boolean is begin 

             return IsReady(this.tx);
          
end function txIsReady; 

 procedure txSetData(this : inout AxiRXTXMaster_axiDWordBi; data : in DWORD_data_t) is begin 

            SetData(this.tx, data);
          
end procedure txSetData; 

 procedure txSetLast(this : inout AxiRXTXMaster_axiDWordBi) is begin 

            SetLast(this.tx);
          
end procedure txSetLast; 

 function  txIsLast(this :  AxiRXTXMaster_axiDWordBi) return boolean is begin 

            return this.tx.ctrl.DataLast = '1';
          
end function txIsLast; 

 function  txIsValid(this :  AxiRXTXMaster_axiDWordBi) return boolean is begin 

            return this.tx.ctrl.DataValid = '1';
          
end function txIsValid; 

 function  txGetData(this :  AxiRXTXMaster_axiDWordBi) return DWORD_data_t is begin 

            return this.tx.Data;
          
end function txGetData; 

 function  txGetPos(this :  AxiRXTXMaster_axiDWordBi) return size_t is begin 

            return this.tx.position;
          
end function txGetPos; 

 function  rxIsValidAndReady(this :  AxiRXTXMaster_axiDWordBi) return boolean is begin 

            return IsValid(this.rx) and wasReady(this.rx);  
          
end function rxIsValidAndReady; 

 function  rxGetData(this :  AxiRXTXMaster_axiDWordBi) return DWORD_data_t is begin 

            if not rxIsValidAndReady(this) then 
              report "Error data already set";
            end if;
            return this.rx.data;
          
end function rxGetData; 

 procedure rxSetReady(this : inout AxiRXTXMaster_axiDWordBi) is begin 

            this.rx.Ready := '1';
          
end procedure rxSetReady; 

 function  rxGetPos(this :  AxiRXTXMaster_axiDWordBi) return size_t is begin 

            return this.rx.position;
          
end function rxGetPos; 

 function  rxIsLast(this :  AxiRXTXMaster_axiDWordBi) return boolean is begin 

            return this.rx.ctrl.DataLast = '1';
          
end function rxIsLast; 

 -- End Pseudo class AxiRXTXMaster_axiDWordBi



-- Starting Pseudo class AxiRXTXSlave_axiDWordBi
  procedure AxiPullData(this : inout AxiRXTXSlave_axiDWordBi; signal fMaster : in AxiFromMaster_axiDWordBi) is begin 

            pullSender(this.tx, fMaster.RX_Ready);
            pullReceiver(this.rx, fMaster.TX_Data ,fMaster.TX_ctrl.DataLast,  fMaster.TX_ctrl.DataValid);

           
end procedure AxiPullData; 

 procedure AxiPushData(this : inout AxiRXTXSlave_axiDWordBi; signal toMaster : out AxiToMaster_axiDWordBi) is begin 

            pushSender(this.tx, toMaster.RX_Data ,toMaster.RX_ctrl.DataLast,toMaster.RX_ctrl.DataValid );
            pushReceiver(this.rx, toMaster.TX_Ready);
           
end procedure AxiPushData; 

 procedure AxiPullData(this : inout AxiRXTXSlave_axiDWordBi; signal RX_Ready : in sl; signal TX_Data : in DWORD_data_t; signal TXDataValid : in sl; signal TXDataLast : in sl) is begin 

            pullSender(this.tx, RX_Ready);
            pullReceiver(this.rx, TX_Data , TXDataLast ,  TXDataValid);

           
end procedure AxiPullData; 

 procedure AxiPushData(this : inout AxiRXTXSlave_axiDWordBi; signal TX_Ready : out sl; signal RX_Data : out DWORD_data_t; signal RX_DataValid : out sl;  signal RX_DataLast : out sl) is begin 

            pushSender(this.tx, RX_Data , RX_DataLast, RX_DataValid);
            pushReceiver(this.rx, TX_Ready);
           
end procedure AxiPushData; 

 function  txIsReady(this :  AxiRXTXSlave_axiDWordBi) return boolean is begin 

             return IsReady(this.tx);
          
end function txIsReady; 

 procedure txSetData(this : inout AxiRXTXSlave_axiDWordBi; data : in DWORD_data_t) is begin 

            SetData(this.tx, data);
          
end procedure txSetData; 

 procedure txSetLast(this : inout AxiRXTXSlave_axiDWordBi) is begin 

            SetLast(this.tx);
          
end procedure txSetLast; 

 function  txIsLast(this :  AxiRXTXSlave_axiDWordBi) return boolean is begin 

            return this.tx.ctrl.DataLast = '1';
          
end function txIsLast; 

 function  txIsValid(this :  AxiRXTXSlave_axiDWordBi) return boolean is begin 

            return this.tx.ctrl.DataValid = '1';
          
end function txIsValid; 

 function  txGetData(this :  AxiRXTXSlave_axiDWordBi) return DWORD_data_t is begin 

            return this.tx.Data;
          
end function txGetData; 

 function  txGetPos(this :  AxiRXTXSlave_axiDWordBi) return size_t is begin 

            return this.tx.position;
          
end function txGetPos; 

 function  rxIsValidAndReady(this :  AxiRXTXSlave_axiDWordBi) return boolean is begin 

            return IsValid(this.rx) and wasReady(this.rx);  
          
end function rxIsValidAndReady; 

 function  rxGetData(this :  AxiRXTXSlave_axiDWordBi) return DWORD_data_t is begin 

            if not rxIsValidAndReady(this) then 
              report "Error data already set";
            end if;
            return this.rx.data;
          
end function rxGetData; 

 procedure rxSetReady(this : inout AxiRXTXSlave_axiDWordBi) is begin 

            this.rx.Ready := '1';
          
end procedure rxSetReady; 

 function  rxGetPos(this :  AxiRXTXSlave_axiDWordBi) return size_t is begin 

            return this.rx.position;
          
end function rxGetPos; 

 function  rxIsLast(this :  AxiRXTXSlave_axiDWordBi) return boolean is begin 

            return this.rx.ctrl.DataLast = '1';
          
end function rxIsLast; 

 -- End Pseudo class AxiRXTXSlave_axiDWordBi

end package body axiDWORDbi_p;

