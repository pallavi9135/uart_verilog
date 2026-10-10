module uart_rx #(parameter CLKS_PER_BIT = 868)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_valid,
    output reg        frame_err
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift;
    reg rx_m, rx_s;

    always @(posedge clk) begin rx_m <= rx; rx_s <= rx_m; end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; clk_cnt <= 0; bit_idx <= 0; shift <= 0;
            rx_data <= 0; rx_valid <= 0; frame_err <= 0;
        end else begin
            rx_valid <= 1'b0;
            case (state)
                IDLE: begin
                    clk_cnt <= 0; bit_idx <= 0;
                    if (rx_s == 1'b0) state <= START;
                end
                START: begin
                    if (clk_cnt == (CLKS_PER_BIT-1)/2) begin
                        clk_cnt <= 0;
                        if (rx_s == 1'b0) state <= DATA;
                        else state <= IDLE;
                    end else clk_cnt <= clk_cnt + 1;
                end
                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        shift[bit_idx] <= rx_s;
                        if (bit_idx == 3'd7) begin bit_idx <= 0; state <= STOP; end
                        else bit_idx <= bit_idx + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end
                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        rx_data <= shift; rx_valid <= 1'b1;
                        frame_err <= ~rx_s;
                        state <= IDLE;
                    end else clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end
endmodule