module uart_rx #(
    parameter int CLKS_PER_BIT = 868
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       rx,
    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       frame_err
);
    localparam int CNT_W = $clog2(CLKS_PER_BIT);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t           state;
    logic [CNT_W-1:0] clk_cnt;
    logic [2:0]       bit_idx;
    logic [7:0]       shift;
    logic             rx_m, rx_s;

    always_ff @(posedge clk) begin
        rx_m <= rx;
        rx_s <= rx_m;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            clk_cnt   <= '0;
            bit_idx   <= '0;
            shift     <= '0;
            rx_data   <= '0;
            rx_valid  <= 1'b0;
            frame_err <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            case (state)
                IDLE: begin
                    clk_cnt <= '0;
                    bit_idx <= '0;
                    if (!rx_s) state <= START;
                end
                START: begin
                    if (clk_cnt == (CLKS_PER_BIT-1)/2) begin
                        clk_cnt <= '0;
                        state   <= (!rx_s) ? DATA : IDLE;
                    end else clk_cnt <= clk_cnt + 1'b1;
                end
                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt        <= '0;
                        shift[bit_idx] <= rx_s;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= '0;
                            state   <= STOP;
                        end else bit_idx <= bit_idx + 1'b1;
                    end else clk_cnt <= clk_cnt + 1'b1;
                end
                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt   <= '0;
                        rx_data   <= shift;
                        rx_valid  <= 1'b1;
                        frame_err <= ~rx_s;
                        state     <= IDLE;
                    end else clk_cnt <= clk_cnt + 1'b1;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
