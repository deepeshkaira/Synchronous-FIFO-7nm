set_app_var search_path [concat $search_path [list ./rtl ./constraints ./lib/asap7_db]]

set_app_var target_library [list \
    asap7sc7p5t_AO_RVT_TT_08302018.db \
    asap7sc7p5t_INVBUF_RVT_TT_08302018.db \
    asap7sc7p5t_OA_RVT_TT_08302018.db \
    asap7sc7p5t_SEQ_RVT_TT_08302018.db \
    asap7sc7p5t_SIMPLE_RVT_TT_08302018.db \
]

set_app_var link_library [concat "*" $target_library]

file mkdir netlist
file mkdir reports/synthesis
file mkdir reports/synthesis/sync_fifo_ungated

analyze -format sverilog rtl/sync_fifo.sv
elaborate sync_fifo
current_design sync_fifo
link

check_design > reports/synthesis/sync_fifo.rpt

read_sdc constraints/sync_fifo.sdc

#set_clock_gating_style \
#    -sequential_cell latch \
#    -positive_edge_logic {integrated} \
#    -minimum_bitwidth 1 \
#    -control_point before

compile_ultra

report_clock_gating > reports/synthesis/sync_fifo_clock_gating.rpt

set_fix_multiple_port_nets -all -buffer_constants
change_names -rules verilog -hierarchy

report_qor > reports/synthesis/sync_fifo_ungated/sync_fifo_qor.rpt
report_area -hierarchy > reports/synthesis/sync_fifo_ungated/sync_fifo_area.rpt
report_timing -max_paths 10 > reports/synthesis/sync_fifo_ungated/sync_fifo_timing.rpt
report_power -hierarchy > reports/synthesis/sync_fifo_ungated/sync_fifo_power_estimate.rpt
report_reference -hierarchy > reports/synthesis/sync_fifo_ungated/sync_fifo_references.rpt

write -format ddc -hierarchy -output netlist/sync_fifo_ungated.ddc
write -format verilog -hierarchy -output netlist/sync_fifo_ungated.v
write_sdc netlist/sync_fifo_ungated.sdc

exit
