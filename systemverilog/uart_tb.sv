`timescale 1ns/1ps
module uart_tb;
    localparam int CLKS = 16;

    logic       clk = 1'b0, rst = 1'b1, tx_start = 1'b0;
    logic [7:0] tx_data = '0;
    logic       tx_line, tx_busy, tx_done, rx_valid, frame_err;
    logic [7:0] rx_data;

    logic [7:0] exp_q[$];
    logic [7:0] expected;
    int         pass_cnt = 0, fail_cnt = 0;

    logic [7:0] directed [5] = '{8'hA5, 8'h3C, 8'hFF, 8'h00, 8'h55};

    always #5 clk = ~clk;

    uart_tx #(.CLKS_PER_BIT(CLKS)) TX (
        .clk, .rst, .tx_start, .tx_data,
        .tx(tx_line), .tx_busy, .tx_done
    );
    uart_rx #(.CLKS_PER_BIT(CLKS)) RX (
        .clk, .rst, .rx(tx_line),
        .rx_data, .rx_valid, .frame_err
    );

    always @(posedge clk) begin
        if (rx_valid) begin
            if (exp_q.size() == 0) begin
                $error("Unexpected byte received: %h", rx_data);
                fail_cnt++;
            end else begin
                expected = exp_q.pop_front();
                if (rx_data === expected && !frame_err) begin
                    pass_cnt++;
                    $display("PASS: sent %h, got %h", expected, rx_data);
                end else begin
                    fail_cnt++;
                    $error("FAIL: sent %h, got %h, frame_err=%b", expected, rx_data, frame_err);
                end
            end
        end
    end

    task automatic send_byte(input logic [7:0] b);
        exp_q.push_back(b);
        @(posedge clk); tx_data <= b; tx_start <= 1'b1;
        @(posedge clk); tx_start <= 1'b0;
        @(posedge tx_done);
        repeat (8) @(posedge clk);
    endtask

    initial begin
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (5) @(posedge clk);

        foreach (directed[i]) send_byte(directed[i]);
        repeat (10) send_byte($urandom_range(0, 255));

        repeat (50) @(posedge clk);
        if (exp_q.size() != 0) begin
            $error("%0d byte(s) were never received", exp_q.size());
            fail_cnt++;
        end
        $display("---- %0d passed, %0d failed ----", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("TEST PASSED");
        else               $display("TEST FAILED");
        $finish;
    end
endmodule
