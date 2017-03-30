from __future__ import print_function
import sys
import re

rom_fname   = sys.argv[1]
fd_init     = open(rom_fname,'r')
rom_name    = rom_fname.split('.')[0]
fd_result   = open("{0}_switch.vhd".format(rom_name),'w')

init_data = ""
initp_data = ""

for line in fd_init :
    match = re.search(r"attribute INIT_([0-9A-F]+) of bram : label is \"([0-9A-F]+)\" ;",line)
    if(match):
        init_data_int = int(match.group(2),16)
        init_data_bin = bin(init_data_int)
        init_data_str_tmp = str(init_data_bin)[2:].zfill(256)
        init_data = init_data_str_tmp + init_data
    else :
        match = re.search(r"attribute INITP_([0-9A-F]+) of bram : label is \"([0-9A-F]+)\" ;",line)
        if(match):
            initp_data_int = int(match.group(2),16)
            initp_data_bin = bin(initp_data_int)
            initp_data_str_tmp = str(initp_data_bin)[2:].zfill(256)
            initp_data = initp_data_str_tmp + initp_data

addrmax = len(init_data)/16

init_data   = init_data[::-1]
initp_data  = initp_data[::-1]

print("library ieee;",file=fd_result)
print("use ieee.std_logic_1164.all;",file=fd_result)
print("use ieee.numeric_std.all;",file=fd_result)
print("",file=fd_result)
print("entity {0} is".format(rom_name),file=fd_result)
print("  port (",file=fd_result)
print("    clk_i    : in std_logic;",file=fd_result)
print("    addr_i   : in std_logic_vector(9 downto 0);",file=fd_result)
print("    data_o   : out std_logic_vector(17 downto 0)",file=fd_result)
print("  );",file=fd_result)
print("end {0} ;".format(rom_name),file=fd_result)
print("",file=fd_result)
print("architecture behavioral of {0} is".format(rom_name),file=fd_result)
print("begin",file=fd_result)
print("  read : process(clk_i)",file=fd_result)
print("  begin",file=fd_result)
print("    if(clk_i'event and clk_i = '1') then",file=fd_result)
print("      case to_integer(unsigned(addr_i)) is",file=fd_result)

for addr in range(addrmax) :
    data_tmp = init_data[addr*16:(addr*16)+16]
    data_tmp = data_tmp[::-1]
    datap_tmp = initp_data[addr*2:(addr*2)+2]
    datap_tmp = datap_tmp[::-1]
    data = datap_tmp + data_tmp

    print("        when {0} => data_o <= \"{1}\";".format(addr,data),file=fd_result)

print("        when others => data_o <= (OTHERS => \'0\');".format(addr,data),file=fd_result)
print("      end case;",file=fd_result)
print("    end if;",file=fd_result)
print("  end process;",file=fd_result)

print("end behavioral;",file=fd_result)






