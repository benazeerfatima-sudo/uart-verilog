`timescale 1ns/1ps

module uart_tx #(
    parameter CPB = 16
)(
    input clk,
    input reset_n,
    input tx_start,
    input [7:0] tx_data,
    output reg tx,
    output reg tx_busy
);

    reg [7:0] data_shift;
    integer count;
    integer bit_index;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx         <= 1'b1;
            tx_busy    <= 1'b0;
            data_shift <= 8'b0;
            count      <= 0;
            bit_index  <= 0;
        end else begin
            if (!tx_busy) begin
                tx <= 1'b1;
                count <= 0;

                if (tx_start) begin
                    data_shift <= tx_data;
                    tx         <= 1'b0;
                    tx_busy    <= 1'b1;
                    bit_index  <= 0;
                end
            end else begin
                if (count == CPB-1) begin
                    count <= 0;

                    if (bit_index < 8) begin
                        tx <= data_shift[0];
                        data_shift <= {1'b0, data_shift[7:1]};
                        bit_index <= bit_index + 1;
                    end else if (bit_index == 8) begin
                        tx <= 1'b1;
                        bit_index <= 9;
                    end else begin
                        tx <= 1'b1;
                        tx_busy <= 1'b0;
                    end
                end else begin
                    count <= count + 1;
                end
            end
        end
    end

endmodule


module uart_rx #(
    parameter CPB = 16
)(
    input clk,
    input reset_n,
    input rx,
    output reg [7:0] rx_data,
    output reg rx_valid
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg rx_meta, rx_sync;
    reg [7:0] shift_reg;
    integer count;
    integer bit_index;

    // Synchronize the asynchronous serial input
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state     <= IDLE;
            rx_data   <= 8'b0;
            rx_valid  <= 1'b0;
            shift_reg <= 8'b0;
            count     <= 0;
            bit_index <= 0;
        end else begin
            rx_valid <= 1'b0;

            case (state)
                IDLE: begin
                    count <= 0;
                    bit_index <= 0;

                    if (rx_sync == 1'b0)
                        state <= START;
                end

                START: begin
                    if (count == (CPB/2)-1) begin
                        count <= 0;

                        if (rx_sync == 1'b0)
                            state <= DATA;
                        else
                            state <= IDLE;
                    end else begin
                        count <= count + 1;
                    end
                end

                DATA: begin
                    if (count == CPB-1) begin
                        count <= 0;
                        shift_reg[bit_index] <= rx_sync;

                        if (bit_index == 7) begin
                            bit_index <= 0;
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        count <= count + 1;
                    end
                end

                STOP: begin
                    if (count == CPB-1) begin
                        count <= 0;
                        state <= IDLE;

                        if (rx_sync == 1'b1) begin
                            rx_data <= shift_reg;
                            rx_valid <= 1'b1;
                        end
                    end else begin
                        count <= count + 1;
                    end
                end

                default: begin
                    state <= IDLE;
                    count <= 0;
                end
            endcase
        end
    end

endmodule
