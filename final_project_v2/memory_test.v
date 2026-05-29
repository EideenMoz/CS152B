`timescale 1ns / 1ps

module memory_test(
    input [3:0] sw,      // 4 switches to select 1 of 16 memory addresses
    output [15:0] led    // 16 LEDs to show the data stored at that address
    );

    // Declare the memory array: 16 rows deep, 16 bits wide
    reg [15:0] rom_memory [0:60000];

    // Load the external file into the memory during synthesis
    initial begin
        $readmemh("hello_there.mem", rom_memory);
    end

    // Continuously output the memory data based on the switch address
    assign led = rom_memory[sw];

endmodule