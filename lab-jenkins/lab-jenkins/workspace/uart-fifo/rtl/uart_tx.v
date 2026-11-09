// rtl/uart_tx.v – émetteur UART 8N1
module uart_tx #(
    parameter CLK_HZ = 100_000_000,
    parameter BAUD   = 115_200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output wire       busy
);
    localparam integer DIV = CLK_HZ / BAUD;

    reg [$clog2(DIV)-1:0] cnt;
    reg [3:0]             bit_idx;
    reg [9:0]             shift;
    reg                   active;

    assign busy = active;

    always @(posedge clk) begin
        if (rst) begin
            tx <= 1'b1; active <= 1'b0; cnt <= 0; bit_idx <= 0;
        end else if (!active) begin
            tx <= 1'b1;
            if (start) begin
                shift   <= {1'b1, data, 1'b0};   // stop, données, start
                active  <= 1'b1;
                cnt     <= 0;
                bit_idx <= 0;
            end
        end else begin
            tx <= shift[0];
            if (cnt == DIV - 1) begin
                cnt   <= 0;
                shift <= {1'b1, shift[9:1]};
                if (bit_idx == 4'd9) active <= 1'b0;
                else bit_idx <= bit_idx + 1'b1;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
