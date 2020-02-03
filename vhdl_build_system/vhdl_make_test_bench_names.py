

def get_reader_entity_name(entityDef):
    et_name = entityDef.name()
    reader_entity = et_name +"_reader_et"
    return reader_entity

def get_writer_entity_name(entityDef):
    et_name = entityDef.name()
    reader_entity = et_name +"_writer_et"
    return reader_entity

def get_reader_pgk_name(entityDef):
    et_name = entityDef.name()

    pgk_name = et_name +"_reader_pgk"
    return pgk_name

def get_writer_pgk_name(entityDef):
    et_name = entityDef.name()

    pgk_name = et_name +"_writer_pgk"
    return pgk_name
    
def get_IO_pgk_name(entityDef):
    et_name = entityDef.name()

    pgk_name = et_name +"_IO_pgk"
    return pgk_name

def get_reader_record_name(entityDef):
    et_name = entityDef.name()
    record_name = et_name +"_reader_rec"
    return record_name

def get_writer_record_name(entityDef):
    et_name = entityDef.name()
    record_name = et_name +"_writer_rec"
    return record_name

def get_includes():
    ret = '''
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.type_conversions_pgk.all;
use work.CSV_UtilityPkg.all;

'''
    return ret

