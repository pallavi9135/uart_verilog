module uart_top #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD     = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       uart_rx_in,
    output wire       uart_tx_out,
    output reg  [7:0] led
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;

    wire [7:0] rx_data;
    wire rx_valid, frame_err, tx_busy, tx_done;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .clk(clk), .rst(rst), .rx(uart_rx_in),
        .rx_data(rx_data), .rx_valid(rx_valid), .frame_err(frame_err));

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk(clk), .rst(rst), .tx_start(rx_valid), .tx_data(rx_data),
        .tx(uart_tx_out), .tx_busy(tx_busy), .tx_done(tx_done));

    always @(posedge clk)
        if (rst) led <= 8'h00;
        else if (rx_valid) led <= rx_data;
endmodule