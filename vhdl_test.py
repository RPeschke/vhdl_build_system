#!/usr/bin/python
import sys

import os,sys,inspect
from  vhdl_parser import *
from  vhdl_get_dependencies import *
from  vhdl_get_entity_def import *

t= get_text_between_outtermost("std_logic_vector(10 downto 0)" ,"(",")")
print(t)
if t == "10 downto 0":
    print("sucess")
else:
    print("fail")


t= get_text_between_outtermost("(std_logic_vector(10 downto 0)) " ,"(",")")
print(t)