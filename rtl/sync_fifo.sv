`timescale 1ns/1ps

module sync_fifo #(
        parameter int FOLD_WIDTH = 23
    ) (
        input logic clk,
        input logic rst_n,
        input logic en_i,

        /// write signals for the fifo
        input logic wr_en_i,
        input logic [FOLD_WIDTH-1:0] folded_history_i ,
        // input logic misprediction_i,

        // read enable flag
        input logic rd_en_i,

        output logic fifo_full_o,
        output logic fifo_empty_o,
	output logic [FOLD_WIDTH-1:0]read_data_o
    );

        // Number of bits required to address the FIFO memory
	localparam int DEPTH = 8;
        localparam int ADDR_WIDTH = $clog2(DEPTH);

        // Pointers contain one additional MSB for wrap detection
        logic [ADDR_WIDTH:0] write_pointer;
        logic [ADDR_WIDTH:0] next_write_pointer;
        logic [ADDR_WIDTH:0] read_pointer;
        logic [ADDR_WIDTH:0] next_read_pointer;

	logic [FOLD_WIDTH-1:0] folded_history_gated;

        logic fifo_full_next;
        logic fifo_empty_next;
        logic write_enable;
        logic read_enable;

        logic gated_write_clk;
        logic gated_read_clk;

        logic [FOLD_WIDTH-1:0] fifo_mem [0:DEPTH-1];
        logic [FOLD_WIDTH-1:0] read_data_q;

        assign read_enable = en_i && rd_en_i && !fifo_empty_o;
        assign write_enable = en_i && wr_en_i && (!fifo_full_o || read_enable);

        // FIFO EMPTY FLAG GENERATION - FIFO will be empty after this cycle when the complete next read and write pointers are equal.
        assign fifo_empty_next = (next_read_pointer == next_write_pointer);

        // FIFO FULL FLAG GENERATION - Lower address bits must be equal. Extra pointer MSBs must be different. next_read_pointer is used because this synchronous FIFO permits simultaneous read and write operations.
        assign fifo_full_next = (next_write_pointer[ADDR_WIDTH] != next_read_pointer[ADDR_WIDTH]) && (next_write_pointer[ADDR_WIDTH-1:0] == next_read_pointer[ADDR_WIDTH-1:0]);

        // FIFO FULL AND EMPTY FLAGS - they are needed to be done irrespective of write or read clock. Because it can be that the block has disbaled the gating signal for read and write clock. 
		// but in this process we might not be able to send out the FIFO full or empty signals out of the block which might result in the External block keep on sending the data packets - becaue it does not know that
		// the FIFO is not processing any and it will lead to loss of data packets eventually.
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                fifo_full_o  <= 1'b0;
                fifo_empty_o <= 1'b1;
            end
            else if (en_i) begin
                fifo_full_o  <= fifo_full_next;
                fifo_empty_o <= fifo_empty_next;
            end
        end

/*        // WRITE CLOCK GATING
        gated_clk u_write_clock_gate (
            .clk_i       (clk),
            .en_i        (write_enable),
            .clk_gated_o (gated_write_clk)
        );

        // READ CLOCK GATING
        gated_clk u_read_clock_gate (
            .clk_i       (clk),
            .en_i        (read_enable),
            .clk_gated_o (gated_read_clk)
        );
*/

		// NEXT WRITE POINTER: The lower bits address memory. The additional MSB automatically toggles when the lower address portion wraps around.
        assign next_write_pointer = write_pointer + {{ADDR_WIDTH{1'b0}}, write_enable};

        // WRITE POINTER- Advances only when write_enable is asserted.
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n)
                write_pointer <= '0;
            else if(write_enable)
                write_pointer <= next_write_pointer;
        end

        // NEXT READ POINTER
        assign next_read_pointer = read_pointer + {{ADDR_WIDTH{1'b0}}, read_enable};
       
        // READ POINTER- Advances only when read_enable is asserted.
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n)
		begin
			read_pointer <= '0;
			read_data_q <= '0;
		end
            else if(read_enable)
		begin
			read_pointer <= next_read_pointer;
			read_data_q  <= fifo_mem[read_pointer[ADDR_WIDTH-1:0]];						
		end
        end

		// give read data on the output bus
		assign read_data_o = read_data_q;

		/// gate the incoming data packet
		assign folded_history_gated = en_i ? folded_history_i : '0;

        // FIFO DATA WRITE: The lower write-pointer bits select the memory location.
        always_ff @(posedge clk) begin
		if(write_enable)
                fifo_mem[write_pointer[ADDR_WIDTH-1:0]] <= folded_history_i;
        end

endmodule

// gated clock
/*
module gated_clk (
    input  logic clk_i,
    input  logic en_i,

    output logic clk_gated_o
);

    logic en_latched;

    always_latch begin
        if (!clk_i) begin
            en_latched <= en_i;
        end
    end

	assign clk_gated_o = clk_i & en_latched;

endmodule
*/
