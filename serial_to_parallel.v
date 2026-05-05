// ============================================================
// Serial-to-Parallel Converter
// Course  : Computer Architecture and Organization
// Module  : serial_to_parallel
// Description:
//   Converts N bits of serial input data into an N-bit
//   parallel output word.  Data is shifted in MSB-first
//   on every rising edge of clk while shift_en is high.
//   After N bits have been received, data_valid pulses
//   high for one clock cycle.
// Parameters:
//   DATA_WIDTH - number of bits in the parallel word (default 8)
// Ports:
//   clk         - system clock (rising-edge triggered)
//   rst_n       - asynchronous active-low reset
//   serial_in   - 1-bit serial data input (MSB first)
//   shift_en    - enable shifting (1 = accept data)
//   parallel_out- N-bit parallel output register
//   data_valid  - pulses HIGH for 1 cycle when word is ready
// ============================================================

module serial_to_parallel #(
    parameter DATA_WIDTH = 8            // bits per parallel word
)(
    input  wire                   clk,
    input  wire                   rst_n,       // active-low async reset
    input  wire                   serial_in,   // serial data (MSB first)
    input  wire                   shift_en,    // 1 = shifting enabled
    output reg  [DATA_WIDTH-1:0]  parallel_out,// parallel data output
    output reg                    data_valid   // 1-cycle pulse when done
);

    // --------------------------------------------------------
    // Internal counter: counts how many bits have been loaded
    // --------------------------------------------------------
    // We need to count from 0 to DATA_WIDTH-1.
    // $clog2 gives us just enough bits (e.g. 3 bits for 8-wide).
    reg [$clog2(DATA_WIDTH)-1:0] bit_count;

    // --------------------------------------------------------
    // Shift register: collects incoming serial bits
    // --------------------------------------------------------
    reg [DATA_WIDTH-1:0] shift_reg;

    // --------------------------------------------------------
    // Sequential logic (clk / rst_n)
    // --------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // --- Asynchronous reset: clear everything --------
            shift_reg    <= {DATA_WIDTH{1'b0}};
            parallel_out <= {DATA_WIDTH{1'b0}};
            bit_count    <= {$clog2(DATA_WIDTH){1'b0}};
            data_valid   <= 1'b0;

        end else begin
            // Default: de-assert valid every cycle
            data_valid <= 1'b0;

            if (shift_en) begin
                // Shift left and bring in new bit at LSB position
                // This accepts MSB first:
                //   cycle 0: bit_count==0, shift_reg[7]=serial_in (MSB)
                //   cycle 7: bit_count==7, shift_reg[0]=serial_in (LSB)
                shift_reg <= {shift_reg[DATA_WIDTH-2:0], serial_in};
                bit_count <= bit_count + 1'b1;

                // When we have collected DATA_WIDTH bits -> output
                if (bit_count == DATA_WIDTH - 1) begin
                    parallel_out <= {shift_reg[DATA_WIDTH-2:0], serial_in};
                    data_valid   <= 1'b1;
                    bit_count    <= {$clog2(DATA_WIDTH){1'b0}}; // auto-reset counter
                end
            end
        end
    end

endmodule
