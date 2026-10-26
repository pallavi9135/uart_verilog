module uart_top #(
    parameter int CLK_FREQ = 100_000_000,
    parameter int BAUD     = 115200
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       uart_rx_in,
    output logic       uart_tx_out,
    output logic [7:0] led
);
    localparam int CLKS_PER_BIT = CLK_FREQ / BAUD;

    logic [7:0] rx_data;
    logic       rx_valid, frame_err, tx_busy, tx_done;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .clk, .rst, .rx(uart_rx_in),
        .rx_data, .rx_valid, .frame_err
    );

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk, .rst, .tx_start(rx_valid), .tx_data(rx_data),
        .tx(uart_tx_out), .tx_busy, .tx_done
    );

    always_ff @(posedge clk) begin
        if (rst)           led <= '0;
        else if (rx_valid) led <= rx_data;
    end
endmodule
