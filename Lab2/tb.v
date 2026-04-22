module tb();
    reg clk;
    reg rst;
    reg send;
    reg [7:0] data;
    wire tx_line;

    tx transmitter(
        .clk(clk),
        .rst(rst),
        .send(send),
        .data(data),
        .tx_line(tx_line)
    );

    // Clock generation: 10 time units period
    initial clk = 0;
    always #5 clk = ~clk; 

    initial begin
        // --- Initialization & Reset ---
        $display("Starting UART TX Testbench");
        rst = 1;
        send = 0;
        data = 8'h00;
        #100;
        
        rst = 0;
        #20; // Wait a few clock cycles after reset drops

        // --- Test Case 1: Normal Transmission ---
        $display("Time %0t: Test Case 1 - Normal Transmission", $time);
        data = 8'b10101010; // 0xAA
        send = 1;
        #10;      // Hold send high for 1 clock cycle
        send = 0;
        
        // Wait for transmission to finish. 
        // ADJUST THIS DELAY based on your baud rate!
        #1000; 

        // --- Test Case 2: Changing data mid-transmission ---
        $display("Time %0t: Test Case 2 - Changing data mid-transmission", $time);
        data = 8'b11001100; // 0xCC
        send = 1;
        #10;
        send = 0;
        
        #50; // Wait until we are partially through the transmission
        $display("Time %0t: Modifying data bus to 0xFF", $time);
        data = 8'b11111111; // Change to 0xFF. The transmitted data should remain 0xCC.
        
        #1000; // Wait for transmission to finish

        // --- Test Case 3: Reset mid-transmission ---
        data = 8'b01010101; // 0x55
        send = 1;
        #10;
        send = 0;
        
        #50; // Wait until we are somewhere in the middle of the frame
        rst = 1;  // Abort!
        #20;      // Hold reset for a couple of clock cycles
        rst = 0;
        
        #200; // Wait to observe recovery and ensure tx_line stays idle

        $finish; // End simulation
    end

endmodule