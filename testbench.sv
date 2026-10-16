`timescale 1ns/1ps

module tb_uart;

    parameter CPB = 16;

    reg clk;
    reg reset_n;
    reg tx_start;
    reg [7:0] tx_data;

    wire tx;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_valid;

    integer passed;
    integer failed;
    integer i;
    integer timeout;
    reg [7:0] random_byte;

    uart_tx #(.CPB(CPB)) U_TX (
        .clk(clk),
        .reset_n(reset_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    uart_rx #(.CPB(CPB)) U_RX (
        .clk(clk),
        .reset_n(reset_n),
        .rx(tx),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task send_and_check;
        input [7:0] expected_data;
        begin
            wait (tx_busy == 1'b0);

            @(negedge clk);
            tx_data = expected_data;
            tx_start = 1'b1;

            @(negedge clk);
            tx_start = 1'b0;

            timeout = 0;

            while ((rx_valid !== 1'b1) &&
                   (timeout < CPB*12)) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (rx_valid === 1'b1) begin
                if (rx_data === expected_data) begin
                    $display("PASS: TX=%h RX=%h",
                             expected_data, rx_data);
                    passed = passed + 1;
                end else begin
                    $display("FAIL: Expected=%h Got=%h",
                             expected_data, rx_data);
                    failed = failed + 1;
                end
            end else begin
                $display("FAIL: Timeout for byte %h",
                         expected_data);
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        reset_n = 1'b0;
        tx_start = 1'b0;
        tx_data = 8'h00;
        passed = 0;
        failed = 0;
        timeout = 0;
        random_byte = 0;

        $dumpfile("dump.vcd");
        $dumpvars(0, tb_uart);

        repeat (5) @(negedge clk);
        reset_n = 1'b1;
        repeat (5) @(negedge clk);

        $display("UART LOOPBACK TEST STARTED");

        // Four directed tests
        send_and_check(8'h00);
        send_and_check(8'hFF);
        send_and_check(8'h55);
        send_and_check(8'hAA);

        // Fifty additional pseudorandom tests
        for (i = 0; i < 50; i = i + 1) begin
            random_byte = $random;
            send_and_check(random_byte);
        end

        $display("------------------------------");
        $display("TOTAL PASSED = %0d", passed);
        $display("TOTAL FAILED = %0d", failed);

        if ((passed == 54) && (failed == 0))
            $display("TEST PASSED: 54 bytes");
        else
            $display("TEST FAILED");

        $display("------------------------------");
        $finish;
    end

endmodule
