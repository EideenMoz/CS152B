module tb();
    reg clk;
    reg rst;
    reg send;
    reg [7:0] write_data;
    wire [7:0] receiver_data;
    wire done;
    wire error;
    wire tx_line;

    tx transmitter(
        .clk(clk),
        .rst(rst),
        .send(send),
        .data(write_data),
        .tx_line(tx_line)
    );

    rx receiver(
        .clk(clk),
        .rst(rst),
        .rx_line(tx_line),
        .data(receiver_data),
        .done(done),
        .error(error)
    );

    // Clock generation: 10 time units period
    initial clk = 0;
    always #5 clk = ~clk; 

    initial begin
        // --- Initialization & Reset ---
        $display("Starting UART TX Testbench");
        rst = 1;
        send = 0;
        write_data = 8'h00;
        #100;
        
        rst = 0;
        #20; // Wait a few clock cycles after reset drops

        // --- Test Case 1: Normal Transmission ---
        $display("Time %0t: Test Case 1 - Normal Transmission", $time);
        write_data = 8'b10101010; // 0xAA
        send = 1;
        #10;      // Hold send high for 1 clock cycle
        send = 0;
        
        // Wait for transmission to finish. 
        // ADJUST THIS DELAY based on your baud rate!
        #1000; 

        // --- Test Case 2: Changing write_data mid-transmission ---
        $display("Time %0t: Test Case 2 - Changing write_data mid-transmission", $time);
        write_data = 8'b01001100; // 0xCC
        send = 1;
        #10;
        send = 0;
        
        #50; // Wait until we are partially through the transmission
        $display("Time %0t: Modifying write_data bus to 0xFF", $time);
        write_data = 8'b11111111; // Change to 0xFF. The transmitted write_data should remain 0xCC.
        
        #1000; // Wait for transmission to finish

        // --- Test Case 3: Reset mid-transmission ---
        write_data = 8'b01010101; // 0x55
        send = 1;
        #10;
        send = 0;
        
        #50; // Wait until we are somewhere in the middle of the frame
        rst = 1;  // Abort!
        #20;      // Hold reset for a couple of clock cycles
        rst = 0;
        
        #200; // Wait to observe recovery and ensure tx_line stays idle

        // --- test case rx failure --- 
        force tx_line = 0; 
        
        // Hold the force for the duration of 1 bit period
        // Replace '100' with your actual bit period duration
        #100; 
        
        // Release the wire back to the transmitter's control
        release tx_line;
        
        // Wait a bit to observe the rx module's 'error' flag trigger
        #200;
        
        $finish; // End simulation

        


    end

endmodule