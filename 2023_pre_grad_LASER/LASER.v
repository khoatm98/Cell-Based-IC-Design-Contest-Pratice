module LASER (
    input CLK,
    input RST,
    input [3:0] X,
    input [3:0] Y,
    output reg [3:0] C1X,
    output reg [3:0] C1Y,
    output reg [3:0] C2X,
    output reg [3:0] C2Y,
    output reg DONE
);


localparam INPUT_LENGTH = 40;
localparam FSM_INPUT  = 0;
localparam FSM_OUTPUT = 1;
localparam FSM_STEP_TWO = 2;
localparam FSM_ACC_SUM = 3;
localparam FSM_CHECK = 4;
localparam RADIUS = 4;
localparam MAX_GRID = 256;
localparam ACC_SUM_PIPELINE = 5;
reg [3:0] x_list[0:39];
reg [3:0] y_list[0:39];

reg [0:39] points_list_c1;
reg [0:39] points_list_c2;
reg [0:39] points_list_c2_best;
reg [5:0] coverage_c2 ;
reg [5:0] coverage_c2_best ;
wire [0:39] xor_points_list_c1_c2;


reg [2:0] curr_state, next_state;
reg [8:0] input_cnt;
reg [5:0] acc_sum_cnt;


reg [3:0] C1X_ready_r;
reg [3:0] C1Y_ready_r;
reg [3:0] C2X_ready_r;
reg [3:0] C2Y_ready_r;
reg [3:0] C2X_best;
reg [3:0] C2Y_best;

wire found;
wire acc_done;
reg [3:0] C2X_delay_r;
reg [3:0] C2Y_delay_r;
wire [3:0] C2X_wait_w;
wire [3:0] C2Y_wait_w;
reg [5:0] debug;
wire [5:0] abs_x[0:39], abs_y[0:39];
assign found = C2X_ready_r == C2X_best && C2Y_ready_r == C2Y_best;
assign C2X_wait_w = input_cnt[3:0];
assign C2Y_wait_w = input_cnt[7:4];
//Comb circuit
genvar i;
generate
// Count points
for ( i = 0 ; i < 40 ; i = i + 1) begin: count_number_of_points
	assign abs_x[i] = (x_list[i] > C2X_wait_w) ? (x_list[i] - C2X_wait_w) : (C2X_wait_w - x_list[i]);
	assign abs_y[i] = (y_list[i] > C2Y_wait_w) ? (y_list[i] - C2Y_wait_w) : (C2Y_wait_w - y_list[i]);
	always@ (posedge CLK) begin
		case (curr_state)
			FSM_STEP_TWO: begin
				points_list_c2[i] <= (((abs_x[i] + abs_y[i]) <= 4) || (abs_x[i] == 3 && abs_y[i] == 2) || (abs_x[i] == 2 && abs_y[i] == 3)) ;
			end
			default: points_list_c2[i] <= points_list_c2[i];
		endcase
	end
end
endgenerate


assign xor_points_list_c1_c2 = points_list_c2&(points_list_c2^points_list_c1);
integer j;
always @ (posedge CLK) begin
	case (curr_state)
		FSM_ACC_SUM: begin
			coverage_c2 <= coverage_c2 + xor_points_list_c1_c2[acc_sum_cnt*(40/ACC_SUM_PIPELINE) + 0]  + xor_points_list_c1_c2[acc_sum_cnt*(40/ACC_SUM_PIPELINE) + 5]
									   + xor_points_list_c1_c2[acc_sum_cnt*(40/ACC_SUM_PIPELINE) + 1]  + xor_points_list_c1_c2[acc_sum_cnt*(40/ACC_SUM_PIPELINE) + 6]	
									   + xor_points_list_c1_c2[acc_sum_cnt*(40/ACC_SUM_PIPELINE) + 2]  + xor_points_list_c1_c2[acc_sum_cnt*(40/ACC_SUM_PIPELINE) + 7]
									   + xor_points_list_c1_c2[acc_sum_cnt*(40/ACC_SUM_PIPELINE) + 3]  + xor_points_list_c1_c2[acc_sum_cnt*(40/ACC_SUM_PIPELINE) + 4];
									   //+ xor_points_list_c1_c2[acc_sum_cnt*(40/ACC_SUM_PIPELINE) + 4]  + xor_points_list_c1_c2[acc_sum_cnt*(40/ACC_SUM_PIPELINE) + 9];
/* 			+ points_list_c2[acc_sum_cnt*10 + 0]^points_list_c1[acc_sum_cnt*10 + 0]  + points_list_c2[acc_sum_cnt*10 + 5]^points_list_c1[acc_sum_cnt*10 + 5]
									   + points_list_c2[acc_sum_cnt*10 + 1]^points_list_c1[acc_sum_cnt*10 + 1]	+ points_list_c2[acc_sum_cnt*10 + 6]^points_list_c1[acc_sum_cnt*10 + 6]	
									   + points_list_c2[acc_sum_cnt*10 + 2]^points_list_c1[acc_sum_cnt*10 + 2]  + points_list_c2[acc_sum_cnt*10 + 7]^points_list_c1[acc_sum_cnt*10 + 7]
									   + points_list_c2[acc_sum_cnt*10 + 3]^points_list_c1[acc_sum_cnt*10 + 3]  + points_list_c2[acc_sum_cnt*10 + 8]^points_list_c1[acc_sum_cnt*10 + 8]
									   + points_list_c2[acc_sum_cnt*10 + 4]^points_list_c1[acc_sum_cnt*10 + 4]  + points_list_c2[acc_sum_cnt*10 + 9]^points_list_c1[acc_sum_cnt*10 + 9]; */
									   
									   
			
		end
		default: coverage_c2 <= 0;
	endcase
end

always@ (*) begin
	DONE = curr_state == FSM_OUTPUT;
	C1X = C1X_ready_r;
	C1Y = C1Y_ready_r;
	C2X = C2X_best;
	C2Y = C2Y_best;
end

// FSM
always@ (*) begin
	case(curr_state)
		FSM_INPUT: next_state = input_cnt == INPUT_LENGTH - 1 ? FSM_STEP_TWO : FSM_INPUT;
		FSM_STEP_TWO : next_state = input_cnt == MAX_GRID? FSM_CHECK : FSM_ACC_SUM; // c1 is fixed
		FSM_ACC_SUM : next_state = acc_sum_cnt ==  ACC_SUM_PIPELINE - 1 ? FSM_STEP_TWO : FSM_ACC_SUM; // c1 is fixed
		FSM_CHECK : next_state = found ? FSM_OUTPUT : FSM_STEP_TWO; // assign c2 as c1, check if optimized result is obtained
		FSM_OUTPUT : next_state = FSM_INPUT;
	endcase
end

// Seq circuit
always @ (posedge CLK) begin
	if(RST) begin
		curr_state <= FSM_INPUT;
	end
	else begin
		curr_state <= next_state;
	end
end

always @ (posedge CLK) begin
	if (curr_state == FSM_CHECK)
		$display("%d", coverage_c2);

end

always @ (posedge CLK) begin
	case (curr_state)
		FSM_STEP_TWO: begin
			C1X_ready_r <= C1X_ready_r;
			C1Y_ready_r <= C1Y_ready_r;
			C2X_ready_r <= coverage_c2 >= coverage_c2_best ? C2X_delay_r : C2X_ready_r;
			C2Y_ready_r <= coverage_c2 >= coverage_c2_best ? C2Y_delay_r : C2Y_ready_r;
			points_list_c2_best <= coverage_c2 >= coverage_c2_best ? points_list_c2 : points_list_c2_best;
			coverage_c2_best <= coverage_c2 >= coverage_c2_best ? coverage_c2 : coverage_c2_best;
			C2X_delay_r <= C2X_wait_w;
			C2Y_delay_r <= C2Y_wait_w;
		end
		FSM_CHECK: begin
			points_list_c1 <= points_list_c2_best;
			coverage_c2_best <= 0;
			C1X_ready_r <= C2X_ready_r;
			C1Y_ready_r <= C2Y_ready_r;
			C2X_best <= C1X_ready_r;
			C2Y_best <= C1Y_ready_r;
			C2X_ready_r <= 0;
			C2Y_ready_r <= 0;
		end
		FSM_ACC_SUM: begin
			C1X_ready_r      <= C1X_ready_r     ;
			C1Y_ready_r      <= C1Y_ready_r     ;
			C2X_ready_r      <= C2X_ready_r     ;
			C2Y_ready_r      <= C2Y_ready_r     ;
			points_list_c1   <= points_list_c1  ;
			coverage_c2_best <= coverage_c2_best;
			C2X_best         <= C2X_best        ;
			C2Y_best         <= C2Y_best        ;
		
		end
		default: begin
			C1X_ready_r <= 0;
			C1Y_ready_r <= 0;
			C2X_ready_r <= 0;
			C2Y_ready_r <= 0;
			points_list_c1 <= 0;
			coverage_c2_best <= 0;
			C2X_best <= 0;
			C2Y_best <= 0;
		
		end
	endcase
end


always @ (posedge CLK) begin
	if(RST) begin
		input_cnt <= 0;
		acc_sum_cnt <= 0;
	end
	else if(curr_state == FSM_STEP_TWO) begin
		input_cnt <= input_cnt == MAX_GRID ? 0 : input_cnt + 1;
		acc_sum_cnt <= 0;
	end
	else if(curr_state == FSM_INPUT) begin
		input_cnt <= input_cnt == INPUT_LENGTH - 1  ? 0 : input_cnt + 1;
		acc_sum_cnt <= 0;
	end
	else if(curr_state == FSM_ACC_SUM) begin
		input_cnt <= input_cnt;
		acc_sum_cnt <= acc_sum_cnt == ACC_SUM_PIPELINE - 1 ? 0 : acc_sum_cnt + 1;
	end
	else begin
		input_cnt <= 0;
		acc_sum_cnt <= 0;
	end
end


generate
for ( i = 0; i < 40; i = i + 1) begin: subject_init
	always @ (posedge CLK) begin
		if(RST) begin
			x_list[i] <= 0;
			y_list[i] <= 0;
		end
		else if (curr_state == FSM_INPUT) begin
			x_list[i] <= input_cnt == i ? X : x_list[i];
			y_list[i] <= input_cnt == i ? Y : y_list[i];
		end else if (curr_state == FSM_OUTPUT) begin
			x_list[i] <= 0;
			y_list[i] <= 0;
		end
		else begin
			x_list[i] <= x_list[i];
			y_list[i] <= y_list[i];
		end
	end
end
endgenerate



endmodule