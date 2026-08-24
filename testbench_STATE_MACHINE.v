// testbench for DE2 simulation 

`timescale 1ns/1ns

module testbench_STATE_MACHINE;

    reg clock;
    reg reset;
    reg beverage_selected;
    reg enough_credit;
    reg dispense_done;
    reg change_done;

    wire dispense_enable;
    wire change_enable;

    // Module under test
    STATE_MACHINE dut (
        .clock(clock),
        .reset(reset),
        .beverage_selected(beverage_selected),
        .enough_credit(enough_credit),
        .dispense_done(dispense_done),
        .change_done(change_done),
        .dispense_enable(dispense_enable),
        .change_enable(change_enable)
);

    // 50 MHz clock -> 20 ns period
    always #10 clock = ~clock;

    initial begin

        // Initial conditions for testing
        clock = 0;
        reset = 0;
        beverage_selected = 0;
        enough_credit = 0;
        dispense_done = 0;
        change_done = 0;

        // -----------------------------------------
        // Test 1: Asynchronous reset
        // -----------------------------------------
        #5;
        reset = 1;

        #5;
        if (dispense_enable !== 0 || change_enable !== 0)
            $display("ERROR: Reset outputs incorrect.");

        #5;
        reset = 0;

        // -----------------------------------------
        // Test 2: IDLE -> SEL
        // -----------------------------------------
        beverage_selected = 1;

        @(posedge clock);
        #1;

        beverage_selected = 0;

        // -----------------------------------------------
        // Test 3: SEL -> CREDIT, unconditional transition
        // -----------------------------------------------
        @(posedge clock);
        #1;

        // ------------------------------------------------
        // Test 4: Waiting for enoug_credit, Credit < Price
        // ------------------------------------------------
        enough_credit = 0;

        repeat (2) begin
            @(posedge clock);
            #1;
        end

        // -----------------------------------------
        // Test 5: CREDIT -> BEV, Credit >= Price
        // -----------------------------------------
        enough_credit = 1;

        @(posedge clock);
        #1;

        enough_credit = 0;

        if (dispense_enable !== 1)
            $display("ERROR: dispense_enable should be HIGH in BEV.");

        // ----------------------------
        // Test 6: Waiting for dispense 
        // ----------------------------
        dispense_done = 0;

        @(posedge clock);
        #1;

        // ---------------------
        // Test 7: BEV -> CHANGE
        // ---------------------
        dispense_done = 1;

        @(posedge clock);
        #1;

        dispense_done = 0;

        if (change_enable !== 1)
            $display("ERROR: change_enable should be HIGH in CHANGE.");

        // ---------------------------------------------------------
        // Test 8: Loop in CHANGE, waiting for change to be returned
        // ---------------------------------------------------------
        change_done = 0;

        @(posedge clock);
        #1;

        // ----------------------
        // Test 9: CHANGE -> IDLE
        // ----------------------
        change_done = 1;

        @(posedge clock);
        #1;

        change_done = 0;

        if (dispense_enable !== 0 || change_enable !== 0)
            $display("ERROR: Outputs should be LOW in IDLE.");
        else
		      $display("FSM simulation completed.");

        #20;
        $stop;

    end

endmodule