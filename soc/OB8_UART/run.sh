mkdir extract

cp src/*.vhd                          extract
cp ../../rtl/OpenBlaze8/src/*.vhd     extract
cp ../../rtl/pbi_OpenBlaze8/src/*.vhd extract
cp ../../rtl/GPIO/src/*.vhd           extract
cp ../../rtl/uart/src/*.vhd           extract
cp ../../rtl/pbi_GPIO/src/*.vhd       extract
cp ../../rtl/pbi_uart/src/*.vhd       extract
cp ../../rtl/lib/src/*.vhd            extract
cp ../../rtl/pbi/src/*.vhd            extract
cp ../../rtl/stack/src/*.vhd          extract
cp ../../rtl/ram_1r1w/src/*.vhd       extract

python ../../softwares/pBlazIDE374/init2rom.py soft/uart_senda.vhd 
mv OpenBlaze8_ROM.vhd                 extract

(
cd nanoxpython 
nanoxpython bitstream.py
)
