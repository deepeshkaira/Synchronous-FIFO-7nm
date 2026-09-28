`timescale 1ns/1ps

import uvm_pkg::*;
import UPF::*;
`include "uvm_macros.svh"

// package
package fifo_params_pkg;
    parameter int FOLD_WIDTH = 23;
endpackage

import fifo_params_pkg::*;

interface fifo_if(input logic clk);
	logic                  rst_n;
	logic                  en_i;
	logic                  wr_en_i;
	logic                  rd_en_i;
	logic [FOLD_WIDTH-1:0] folded_history_i;

	logic [FOLD_WIDTH-1:0] read_data_o;
	logic                  fifo_full_o;
	logic                  fifo_empty_o;
endinterface

class fifo_seq_item extends uvm_sequence_item;

	rand bit                  en_i;
	rand bit                  wr_en_i;
	rand bit                  rd_en_i;
	rand bit [FOLD_WIDTH-1:0] folded_history_i;
	logic                    rst_n;
	logic [FOLD_WIDTH-1:0]   read_data_o;
	logic                    fifo_full_o;
	logic                    fifo_empty_o;

	`uvm_object_utils_begin(fifo_seq_item)
		`uvm_field_int(en_i,             UVM_DEFAULT)
		`uvm_field_int(wr_en_i,          UVM_DEFAULT)
		`uvm_field_int(rd_en_i,          UVM_DEFAULT)
		`uvm_field_int(folded_history_i, UVM_DEFAULT)

		`uvm_field_int(rst_n,            UVM_DEFAULT | UVM_NOCOMPARE)
		`uvm_field_int(read_data_o,      UVM_DEFAULT | UVM_NOCOMPARE)
		`uvm_field_int(fifo_full_o,      UVM_DEFAULT | UVM_NOCOMPARE)
		`uvm_field_int(fifo_empty_o,     UVM_DEFAULT | UVM_NOCOMPARE)
	`uvm_object_utils_end

	function new(string name = "fifo_seq_item");
		super.new(name);
	endfunction

endclass

// base sequence
class fifo_base_sequence extends uvm_sequence #(fifo_seq_item);

	`uvm_object_utils(fifo_base_sequence)

	function new(string name = "fifo_base_sequence");
		super.new(name);
	endfunction

	// One transaction represents one clock cycle.
	task send_cycle(
		bit        rst_n,
		bit        en,
		bit        wr_en,
		bit        rd_en,
		bit [22:0] data
		);

		fifo_seq_item tx;

		tx = fifo_seq_item::type_id::create("tx");
		start_item(tx);

		tx.rst_n            = rst_n;
		tx.en_i             = en;
		tx.wr_en_i          = wr_en;
		tx.rd_en_i          = rd_en;
		tx.folded_history_i = data;

		finish_item(tx);
	endtask

	task reset_fifo(int unsigned cycles = 2);
		repeat (cycles)
			send_cycle(1'b0, 1'b0, 1'b0, 1'b0, '0);
	endtask

	task write_data(bit [22:0] data);
		send_cycle(1'b1, 1'b1, 1'b1, 1'b0, data);
	endtask

	task read_data();
		send_cycle(1'b1, 1'b1, 1'b0, 1'b1, '0);
	endtask

	task read_write(bit [22:0] data);
		send_cycle(1'b1, 1'b1, 1'b1, 1'b1, data);
	endtask

	task idle_cycle();
		send_cycle(1'b1, 1'b1, 1'b0, 1'b0, '0);
	endtask

	// Requests are present, but the global enable blocks both operations.
	task disabled_cycle(bit wr_en, bit rd_en, bit [22:0] data);
		send_cycle(1'b1, 1'b0, wr_en, rd_en, data);
	endtask

endclass


class fifo_active_sequence extends fifo_base_sequence;

	`uvm_object_utils(fifo_active_sequence)

	function new(string name = "fifo_active_sequence");
		super.new(name);
	endfunction

	task body();
		reset_fifo();

		for (int i = 0; i < 12; i++)
			write_data(i + 1);

		write_data(999);       // Attempt write while full
		read_write(1000);      // Replace oldest entry while full

		for (int i = 0; i < 8; i++)
			read_data();

		read_data();           // Attempt read while empty
		disabled_cycle(1, 1, 23'h123456);
		idle_cycle();
	endtask

endclass


/// bodundary sequence
class fifo_boundary_sequence extends fifo_base_sequence;

    `uvm_object_utils(fifo_boundary_sequence)

    function new(string name = "fifo_boundary_sequence");
        super.new(name);
    endfunction

    task body();
        reset_fifo(2);
        idle_cycle();                  // Release reset

        read_data();                   // Empty: read must be rejected
        read_write(23'h000001);        // Empty: accept write, reject read

        // Seven more writes bring occupancy to eight.
        for (int i = 2; i <= 8; i++)
            write_data(i);

        write_data(23'h7FFFFF);        // Full: write must be rejected

        read_write(23'h000009);        // Full: read 1, write 9
                                      // Occupancy remains eight

        // Expect reads of 2, 3, ... 9.
        repeat (8)
            read_data();

        read_data();                   // Empty again: read rejected
        idle_cycle();                  // Read output must hold 9
    endtask

endclass


//// contttrol sequence
class fifo_control_sequence extends fifo_base_sequence;

    `uvm_object_utils(fifo_control_sequence)

    function new(string name = "fifo_control_sequence");
        super.new(name);
    endfunction

    task body();
        reset_fifo(2);
        idle_cycle();

        write_data(23'h0000A1);
        write_data(23'h0000A2);
        write_data(23'h0000A3);
        read_data(); 

		// giving in tthe data but  keeping the enable down
		disabled_cycle(1'b1, 1'b1, 23'h7FFFFF);
        disabled_cycle(1'b1, 1'b0, 23'h123456);
        disabled_cycle(1'b0, 1'b1, '0);

        read_data(); // Expect A2
        read_data(); // Expect A3

        // Each round writes and reads ten words. The pointers wrap repeatedly while several entries remain in the FIFO.
        for (int round = 0; round < 3; round++) begin
            for (int i = 0; i < 6; i++)
                write_data(round * 16 + i);

            repeat (4) read_data();

            for (int i = 6; i < 10; i++)
                write_data(round * 16 + i);

            repeat (6) read_data();
        end

        // Reset while data is present.
        write_data(23'h0000C1);
        write_data(23'h0000C2);
        reset_fifo(2);
        idle_cycle();

        read_data();
        write_data(23'h0000D1);
        read_data();
    endtask

endclass


//// random sequence
class fifo_random_sequence extends fifo_base_sequence;

    `uvm_object_utils(fifo_random_sequence)

    int unsigned num_cycles = 200;

    function new(string name = "fifo_random_sequence");
        super.new(name);
    endfunction

    task body();
        fifo_seq_item tx;

        reset_fifo(2);
        idle_cycle();

        repeat (num_cycles) begin
            tx = fifo_seq_item::type_id::create("tx");
            start_item(tx);

            if (!tx.randomize() with {
                en_i    dist {1'b1 := 8, 1'b0 := 2};
                wr_en_i dist {1'b1 := 6, 1'b0 := 4};
                rd_en_i dist {1'b1 := 6, 1'b0 := 4};
            })
                `uvm_fatal("FIFO/RANDOM_SEQ", "Randomization failed")

            tx.rst_n = 1'b1;
            finish_item(tx);
        end

        // Depth is 8, so eight read requests drain any remaining data. Reads after the FIFO becomes empty should be rejected.
        repeat (8)
            read_data();

        idle_cycle();
    endtask

endclass


/// sequencer for the design
class fifo_sequencer extends uvm_sequencer #(fifo_seq_item);

	`uvm_component_utils(fifo_sequencer)

	function new(string name = "fifo_sequencer", uvm_component parent = null);
		super.new(name,parent);
	endfunction

endclass

/// driver for the testbench
class fifo_driver extends uvm_driver #(fifo_seq_item);

    `uvm_component_utils(fifo_driver)

    virtual fifo_if vif;

    function new(string name = "fifo_driver",uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("FIFO/DRIVER", "fifo_if was not configured")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_seq_item tx;

        vif.rst_n            = 1'b0;
        vif.en_i             = 1'b0;
        vif.wr_en_i          = 1'b0;
        vif.rd_en_i          = 1'b0;
        vif.folded_history_i = '0;

        forever begin
            seq_item_port.get_next_item(tx);

            @(negedge vif.clk);
            vif.rst_n            <= tx.rst_n;
            vif.en_i             <= tx.en_i;
            vif.wr_en_i          <= tx.wr_en_i;
            vif.rd_en_i          <= tx.rd_en_i;
            vif.folded_history_i <= tx.folded_history_i;

            seq_item_port.item_done();
        end
    endtask

endclass


// monitor for the design
class fifo_monitor extends uvm_monitor;

    `uvm_component_utils(fifo_monitor)

    virtual fifo_if vif;
    uvm_analysis_port #(fifo_seq_item) ap;

    function new(string name = "fifo_monitor",uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("FIFO/MONITOR", "fifo_if was not configured")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_seq_item tx;

        forever begin
            @(posedge vif.clk);
            #1ps; // Sample after the DUT's nonblocking assignments.

            tx = fifo_seq_item::type_id::create("observed_tx");

            tx.rst_n            = vif.rst_n;
            tx.en_i             = vif.en_i;
            tx.wr_en_i          = vif.wr_en_i;
            tx.rd_en_i          = vif.rd_en_i;
            tx.folded_history_i = vif.folded_history_i;

            tx.read_data_o      = vif.read_data_o;
            tx.fifo_full_o      = vif.fifo_full_o;
            tx.fifo_empty_o     = vif.fifo_empty_o;

            ap.write(tx);
        end
    endtask

endclass


// scorebaord
class fifo_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(fifo_scoreboard)

    localparam int DEPTH = 8;
    typedef bit [22:0] fifo_data_t;

    uvm_analysis_imp #(fifo_seq_item, fifo_scoreboard) analysis_imp;

    fifo_data_t model_q[$];
    fifo_data_t expected_read_data;

    int unsigned checked_cycles;
    int unsigned accepted_writes;
    int unsigned accepted_reads;

    function new(string name = "fifo_scoreboard",uvm_component parent = null);
        super.new(name, parent);
        analysis_imp = new("analysis_imp", this);
        expected_read_data = '0;
    endfunction

    function void write(fifo_seq_item tx);
        int old_size;
        bit read_accepted;
        bit write_accepted;
        bit expected_full;
        bit expected_empty;
		read_accepted  = 1'b0;
		write_accepted = 1'b0;

        if (tx.rst_n !== 1'b1) begin
            model_q.delete();
            expected_read_data = '0;
        end
        else begin
            old_size = model_q.size();

            read_accepted = tx.en_i && tx.rd_en_i && (old_size > 0);
            write_accepted = tx.en_i && tx.wr_en_i && ((old_size < DEPTH) || read_accepted);

            // Pop first so a full simultaneous read/write returns the old head and inserts the new word at the tail.
            if (read_accepted) begin
                expected_read_data = model_q.pop_front();
                accepted_reads++;
            end

            if (write_accepted) begin
                model_q.push_back(tx.folded_history_i);
                accepted_writes++;
            end
        end

        expected_empty = (model_q.size() == 0);
        expected_full  = (model_q.size() == DEPTH);

        if (tx.fifo_empty_o !== expected_empty)
            `uvm_error("FIFO/EMPTY",
                $sformatf("empty=%b expected=%b occupancy=%0d", tx.fifo_empty_o,expected_empty,model_q.size()))

        if (tx.fifo_full_o !== expected_full)
            `uvm_error("FIFO/FULL",
                $sformatf("full=%b expected=%b occupancy=%0d", tx.fifo_full_o, expected_full, model_q.size()))

        if (tx.read_data_o !== expected_read_data)
            `uvm_error("FIFO/DATA",
                $sformatf("read_data=%h expected=%h en=%b wr=%b rd=%b", tx.read_data_o, expected_read_data, tx.en_i, tx.wr_en_i, tx.rd_en_i))

        checked_cycles++;

		`uvm_info("FIFO/TRACE",
			$sformatf(
				"cycle=%0d rst_n=%b en=%b wr=%b rd=%b | write_accepted=%b read_accepted=%b | data_in=%h data_out=%h | occupancy=%0d full=%b empty=%b | contents=%s",
				checked_cycles,
				tx.rst_n, tx.en_i, tx.wr_en_i, tx.rd_en_i,
				write_accepted, read_accepted,
				tx.folded_history_i, tx.read_data_o,
				model_q.size(), tx.fifo_full_o, tx.fifo_empty_o,
				queue_contents()
			),
			UVM_LOW
		)

    endfunction

	function string queue_contents();
		string text = "[";

		foreach (model_q[i]) begin
			if (i != 0)
				text = {text, ", "};

			text = {text, $sformatf("%0d:%h", i, model_q[i])};
		end

		return {text, "]"};
	endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("FIFO/SUMMARY",
            $sformatf("Checked %0d cycles; accepted %0d writes and %0d reads", checked_cycles, accepted_writes, accepted_reads), UVM_LOW)
    endfunction

endclass


class fifo_agent extends uvm_agent;

    `uvm_component_utils(fifo_agent)

    fifo_sequencer sqr;
    fifo_driver    drv;
    fifo_monitor   mon;

    uvm_analysis_port #(fifo_seq_item) analysis_port;

    function new(string name = "fifo_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = fifo_monitor::type_id::create("mon", this);
        analysis_port = new("analysis_port", this);

        if (get_is_active() == UVM_ACTIVE)
		begin
            sqr = fifo_sequencer::type_id::create("sqr", this);
            drv = fifo_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        mon.ap.connect(analysis_port);

        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass



class fifo_env extends uvm_env;

    `uvm_component_utils(fifo_env)

    fifo_agent      agent;
    fifo_scoreboard scoreboard;

    function new(string name = "fifo_env",uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = fifo_agent::type_id::create("agent", this);
        scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.analysis_port.connect(scoreboard.analysis_imp);
    endfunction

endclass



class fifo_test extends uvm_test;

    `uvm_component_utils(fifo_test)

    fifo_env env;

    function new(string name = "fifo_test",uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_active_sequence active_seq;
		fifo_boundary_sequence boundary_sequence;
		fifo_control_sequence control_sequence;
		fifo_random_sequence random_sequence;

        phase.raise_objection(this);

        // active_seq = fifo_active_sequence::type_id::create("active_seq");
        // active_seq.start(env.agent.sqr);

		// boundary_sequence = fifo_boundary_sequence::type_id::create("boundary_sequence");
        // boundary_sequence.start(env.agent.sqr);

		// control_sequence = fifo_control_sequence::type_id::create("control_sequence");
        // control_sequence.start(env.agent.sqr);

	random_sequence = fifo_random_sequence::type_id::create("random_sequence");
        random_sequence.start(env.agent.sqr);

        // Allow the final driven transaction to reach a rising edge and be checked by the monitor and scoreboard.
        repeat (2) @(posedge env.agent.drv.vif.clk);

        phase.drop_objection(this);
    endtask

endclass


module sync_fifo_tb;

    localparam int FOLD_WIDTH = 23;

    logic clk = 1'b0;
    always #5 clk = ~clk;

    fifo_if intf(clk);

    sync_fifo #(
        .FOLD_WIDTH(FOLD_WIDTH)
    ) dut (
        .clk              (clk),
        .rst_n            (intf.rst_n),
        .en_i             (intf.en_i),
        .wr_en_i          (intf.wr_en_i),
        .folded_history_i (intf.folded_history_i),
        .rd_en_i          (intf.rd_en_i),
        .fifo_full_o      (intf.fifo_full_o),
        .fifo_empty_o     (intf.fifo_empty_o),
        .read_data_o      (intf.read_data_o)
    );

     bit vdd_status;
     bit vss_status;
    
     initial begin
         vdd_status = supply_on("VDD", 0.7);
         vss_status = supply_on("VSS", 0.0);
    
         if (!vdd_status)
             $fatal(1, "Failed to turn on UPF supply port VDD");
    
         if (!vss_status)
             $fatal(1, "Failed to turn on UPF supply port VSS");
     end

    initial begin
        uvm_config_db#(virtual fifo_if)::set(null,"uvm_test_top.env.agent.*","vif",intf);
        run_test("fifo_test");
    end

endmodule