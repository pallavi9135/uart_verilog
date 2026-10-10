`timescale 1ns/1ps
module uart_tb;
    localparam CLKS = 16;
    reg clk = 0, rst = 1, tx_start = 0;
    reg  [7:0] tx_data = 0;
    wire tx_line, tx_busy, tx_done, rx_valid, frame_err;
    wire [7:0] rx_data;

    always #5 clk = ~clk;

    uart_tx #(.CLKS_PER_BIT(CLKS)) TX (.clk(clk), .rst(rst), .tx_start(tx_start),
        .tx_data(tx_data), .tx(tx_line), .tx_busy(tx_busy), .tx_done(tx_done));
    uart_rx #(.CLKS_PER_BIT(CLKS)) RX (.clk(clk), .rst(rst), .rx(tx_line),
        .rx_data(rx_data), .rx_valid(rx_valid), .frame_err(frame_err));

    task send(input [7:0] b);
    begin
        @(posedge clk); tx_data <= b; tx_start <= 1;
        @(posedge clk); tx_start <= 0;
        @(posedge rx_valid);
        #1;
        if (rx_data === b && !frame_err) $display("PASS: sent %h, got %h", b, rx_data);
        else                             $display("FAIL: sent %h, got %h", b, rx_data);
        wait(!tx_busy);
        repeat(5) @(posedge clk);
    end
    endtask

    initial begin
        repeat(5) @(posedge clk); rst = 0;
        repeat(5) @(posedge clk);
        send(8'hA5); send(8'h3C); send(8'hFF); send(8'h00); send(8'h55);
        $display("Simulation complete");
        $finish;
    end
endmodule