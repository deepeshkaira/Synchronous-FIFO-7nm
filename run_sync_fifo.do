vopt sync_fifo_tb +acc -pa_top /sync_fifo_tb/dut -pa_upf upf/sync_fifo_upf.upf -pa_lib work -pa_genrpt=pa+de -o sync_fifo_pa_opt

vsim -sv_seed 12345 sync_fifo_pa_opt -pa -pa_lib work

add wave sim:/sync_fifo_tb/clk
add wave sim:/sync_fifo_tb/intf/rst_n
add wave sim:/sync_fifo_tb/intf/en_i
add wave sim:/sync_fifo_tb/intf/wr_en_i
add wave sim:/sync_fifo_tb/intf/folded_history_i
add wave sim:/sync_fifo_tb/intf/rd_en_i
add wave sim:/sync_fifo_tb/intf/fifo_full_o
add wave sim:/sync_fifo_tb/intf/fifo_empty_o
add wave sim:/sync_fifo_tb/intf/read_data_o

file mkdir saif_reports

# Reset is released at 15 ns. Stop before the first transaction at 20 ns.
run 16ns

power add -r /sync_fifo_tb/dut/*

run -all

power report -all -bsaif saif_reports/sync_fifo.saif
