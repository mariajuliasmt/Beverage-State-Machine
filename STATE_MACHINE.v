// Code in Verilog HDL without .smf auto-generation

module STATE_MACHINE (
	input wire clock,
	input wire reset,
	input wire beverage_selected,
	input wire enough_credit,
	input wire dispense_done,
	input wire change_done,
	output reg dispense_enable,
	output reg change_enable
);
    // MODULE LOGIC
	
    // Encoding using 3 bits
	localparam IDLE   = 3'b000;
	localparam SEL    = 3'b001;
	localparam CREDIT = 3'b010;
	localparam BEV    = 3'b011;
	localparam CHANGE = 3'b100;
    // 3'b101, 3'b110 and 3'b111 == DON'T CARE

	reg [2:0] fstate;
	reg [2:0] reg_fstate;

    // State register
    // Asynchronous active-high reset
	
	always @(posedge clock or posedge reset) begin
		if (reset)
			fstate <= IDLE;
		else
			fstate <= reg_fstate;
	end
	
    // Next-state logic 

	always @(*) begin
		case (fstate)
			IDLE: begin
				if (beverage_selected)
					reg_fstate = SEL;
				else
					reg_fstate = IDLE;
			end
			
			SEL: begin
				reg_fstate = CREDIT;
			end	

			CREDIT: begin
				if (enough_credit)
					reg_fstate = BEV;
				else
					reg_fstate = CREDIT;
			end

			BEV: begin
				if (dispense_done)
					reg_fstate = CHANGE;
				else
					reg_fstate = BEV;
			end

			CHANGE: begin
				if (change_done)
					reg_fstate = IDLE;
				else
					reg_fstate = CHANGE;
			end
		endcase
	end
	
    // Moore output logic
	
    
	always @(*) begin

		// Default outputs
		dispense_enable = 1'b0;
		change_enable   = 1'b0;
        
		case (fstate)
			BEV: begin
				dispense_enable = 1'b1;
			end

			CHANGE: begin
				change_enable = 1'b1;
			end

			default: begin
				// Outputs remain disabled
			end
		endcase
	end
        

endmodule  
