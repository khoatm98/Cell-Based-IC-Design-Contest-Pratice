module CONVEX(
input CLK,
input RST,
input [4:0] PT_XY,
output reg READ_PT,
output reg [9:0] DROP_XY,
output reg DROP_V);

// parameters 
localparam S_RST = 0;
localparam S_READ = 1;
localparam S_CHECK_INSIDE = 2;
localparam S_FIND_SMALLEST = 3;
localparam S_FIND_UPPER = 4;
localparam S_FIND_LOWER = 5;
localparam S_TRANVERSE = 6;
localparam S_OUTPUT = 7;
localparam S_READ_PT = 8;
localparam S_UPDATE = 9;
localparam S_SORT = 10;
localparam S_DROP_NEWP = 11;

localparam MAX_POINTS = 13;
localparam MAX_DROP = 6;
localparam ONE_THIRD  = 8'h2b; // 1/3 fixed point 7 fractional bits
// regs and wires
reg [3:0] cstate, nstate;

reg [9:0] points_X_r[MAX_POINTS :0], points_Y_r[MAX_POINTS :0] ; // 13 points at max + 1 point to make circular queue
reg [9:0] points_X_w[MAX_POINTS :0], points_Y_w[MAX_POINTS :0] ; // 13 points at max + 1 point to make circular queue

reg [9:0] drop_X_r[MAX_DROP-1 :0], drop_Y_r[MAX_DROP-1 :0] ;
reg [9:0] drop_X_w[MAX_DROP-1 :0], drop_Y_w[MAX_DROP-1 :0] ;

reg [9:0] new_point_X_r, new_point_Y_r;

reg [3:0] num_points_r, num_points_w; 
reg [3:0] generic_cnt; // generic cnt 

reg [9:0]  centroid_X_r, centroid_Y_r; // centroid of triangle
reg [18:0] centroid_X_w, centroid_Y_w; // centroid of triangle

reg [2:0] num_drop_r;
reg [3:0] idx_closest_point_r;
reg [20:0] min_distance_r;
// Find tang
reg [3:0] idx_upper_r;
reg [3:0] idx_lower_r;

// Tranverse
reg [3:0] idx_tranverse_r;
reg [4:0] out_cnt_r;
wire is_outside_w;  // if the point is outside of the convex 

// sign conversion
wire signed [10:0] s_xA_w = {1'b0, points_X_r[generic_cnt]};
wire signed [10:0] s_yA_w = {1'b0, points_Y_r[generic_cnt]};
wire signed [10:0] s_xB_w = {1'b0, points_X_r[(generic_cnt+1)%num_points_r]};
wire signed [10:0] s_yB_w = {1'b0, points_Y_r[(generic_cnt+1)%num_points_r]};
wire signed [10:0] s_xC_w = {1'b0, centroid_X_r};
wire signed [10:0] s_yC_w = {1'b0, centroid_Y_r};
wire signed [10:0] s_xP_w = {1'b0, new_point_X_r}; // new point
wire signed [10:0] s_yP_w = {1'b0, new_point_Y_r};

wire signed [10:0] s_xD_w = {1'b0, points_X_r[idx_upper_r]};
wire signed [10:0] s_yD_w = {1'b0, points_Y_r[idx_upper_r]};
wire signed [10:0] s_xE_w = {1'b0, points_X_r[(idx_upper_r+1)%num_points_r]};
wire signed [10:0] s_yE_w = {1'b0, points_Y_r[(idx_upper_r+1)%num_points_r]};

wire signed [10:0] s_xF_w = {1'b0, points_X_r[idx_lower_r]};
wire signed [10:0] s_yF_w = {1'b0, points_Y_r[idx_lower_r]};
wire signed [10:0] s_xG_w = {1'b0, points_X_r[(num_points_r + idx_lower_r - 1) % num_points_r]};
wire signed [10:0] s_yG_w = {1'b0, points_Y_r[(num_points_r + idx_lower_r - 1) % num_points_r]};

wire signed [20:0] side_of_centroid_w = (s_xB_w - s_xA_w)*(s_yC_w - s_yA_w) - (s_yB_w - s_yA_w)*(s_xC_w - s_xA_w);
wire signed [20:0] side_of_newpoint_w = (s_xB_w - s_xA_w)*(s_yP_w - s_yA_w) - (s_yB_w - s_yA_w)*(s_xP_w - s_xA_w);

// Sort closewise triangle
wire signed [20:0] side_of_C_w = (s_xB_w - s_xA_w)*(s_yP_w - s_yA_w) - (s_yB_w - s_yA_w)*(s_xP_w - s_xA_w);

wire [20:0] distance_to_P_w = (s_xA_w - s_xP_w)*(s_xA_w - s_xP_w) + (s_yA_w - s_yP_w)*(s_yA_w - s_yP_w);

reg signed [10:0] xa, ya , xb, yb , xc, yc;
wire signed [20:0] orientation_w = (yb - ya)*(xc - xb) - (yc-yb)*(xb-xa);

assign is_outside_w = side_of_centroid_w[20] != side_of_newpoint_w[20];

integer i;
genvar j;
// Interface
always @(*) begin
    READ_PT = cstate == S_READ_PT;
    DROP_V = cstate == S_OUTPUT && out_cnt_r > 0;
    
    DROP_XY = out_cnt_r[0] ? drop_Y_r[out_cnt_r[4:1]] : drop_X_r[out_cnt_r[4:1] - 1];
end 

// Number of points
always @(*) begin
    case(cstate)
        S_UPDATE : num_points_w = num_drop_r != MAX_DROP + 1 ? num_points_r + 1 - num_drop_r : num_points_r;
        default: num_points_w = num_points_r;
    endcase
end 

// Points update
always @(*) begin
    for (i=0; i<MAX_POINTS+1; i=i+1) begin
        points_X_w[i] = points_X_r[i];
        points_Y_w[i] = points_Y_r[i];
    end
    case(cstate)
        S_UPDATE: begin 
            if(num_drop_r != MAX_DROP+1) begin
                points_X_w[0] = new_point_X_r;
                points_Y_w[0] = new_point_Y_r;

                for (i=1; i<MAX_POINTS; i=i+1) begin
                    points_X_w[i] = points_X_r[(i-1 + idx_upper_r)%num_points_r];
                    points_Y_w[i] = points_Y_r[(i-1 + idx_upper_r)%num_points_r];
                end
            end
        end
        S_SORT: begin
            points_X_w[1] = points_X_r[2];
            points_Y_w[1] = points_Y_r[2];
            points_X_w[2] = points_X_r[1];
            points_Y_w[2] = points_Y_r[1];
        end
        default: begin
            points_X_w[num_points_r] = points_X_r[num_points_r];
            points_Y_w[num_points_r] = points_Y_r[num_points_r];
        end
    endcase
end 

// Points drop
always @(*) begin
    for (i=0; i<MAX_DROP; i=i+1) begin
        drop_X_w[i] = drop_X_r[i];
        drop_Y_w[i] = drop_Y_r[i];
    end
    case(cstate)
        S_TRANVERSE: begin // Make circular queue
            drop_X_w[num_drop_r] = points_X_r[idx_tranverse_r];
            drop_Y_w[num_drop_r] = points_Y_r[idx_tranverse_r];
        end
        S_DROP_NEWP: begin
            drop_X_w[num_drop_r] = new_point_X_r;
            drop_Y_w[num_drop_r] = new_point_Y_r;
        end
        default: begin
            drop_X_w[num_drop_r] = drop_X_r[num_drop_r];
            drop_Y_w[num_drop_r] = drop_Y_r[num_drop_r];
        end
    endcase
end 

// Find centroid
always @(*) begin
    if((cstate == S_READ_PT) && (num_points_r == 3)) begin
        centroid_X_w = (points_X_r[0] + points_X_r[1] + points_X_r[2])*ONE_THIRD;
        centroid_Y_w = (points_Y_r[0] + points_Y_r[1] + points_Y_r[2])*ONE_THIRD;
    end else begin
        centroid_X_w = {2'd0, centroid_X_r, 7'd0};
        centroid_Y_w = {2'd0, centroid_Y_r, 7'd0};
    end
end



// MUX for orientation
always @(*) begin
    case(cstate)
        S_FIND_UPPER : begin
            {xa, ya} = {s_xP_w, s_yP_w};
            {xb, yb} = {s_xD_w, s_yD_w};
            {xc, yc} = {s_xE_w, s_yE_w};
        end
        default: begin
            {xa, ya} = {s_xP_w, s_yP_w};
            {xb, yb} = {s_xF_w, s_yF_w};
            {xc, yc} = {s_xG_w, s_yG_w};
        end
    endcase
end 

// FSN
always @(*) begin
    case(cstate)
        S_RST: nstate = S_READ_PT;
        S_READ_PT: nstate = S_READ;
        S_READ: nstate = generic_cnt[2] ? (num_points_r < 3 ? S_UPDATE : S_CHECK_INSIDE) : S_READ;
        S_CHECK_INSIDE: nstate = is_outside_w ? S_FIND_SMALLEST : ((generic_cnt == num_points_r - 1) ? S_DROP_NEWP : S_CHECK_INSIDE);
        S_FIND_SMALLEST: nstate = (generic_cnt == num_points_r - 1) ? S_FIND_UPPER : S_FIND_SMALLEST;
        S_FIND_UPPER: nstate = orientation_w[20] ? S_FIND_LOWER : S_FIND_UPPER;
        S_FIND_LOWER: nstate = orientation_w > 0  ? S_TRANVERSE : S_FIND_LOWER;
        S_TRANVERSE: nstate = idx_tranverse_r != idx_upper_r ? S_TRANVERSE : S_OUTPUT;
        S_DROP_NEWP: nstate = S_OUTPUT;
        S_OUTPUT: nstate = out_cnt_r == 0 ? S_UPDATE : S_OUTPUT;
        S_UPDATE: nstate = num_points_r==2 && side_of_C_w[20] ? S_SORT : S_READ_PT;
        default: nstate = S_READ_PT;
    endcase
end 


// Sequential
always @(posedge CLK or posedge RST) begin
    if(RST)
        cstate <= S_RST;
    else
        cstate <= nstate;
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        generic_cnt <= 0;
    else begin
        if (cstate != nstate)
            generic_cnt <= 0;
        else
            generic_cnt <= generic_cnt + 1;
    end
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        num_points_r <= 0;
    else begin
        num_points_r <= num_points_w;
    end
end

// new point
always @(posedge CLK) begin
    case(cstate)
        S_READ: begin
            case ( generic_cnt)
                0: begin
                    new_point_X_r <= {PT_XY, 5'b00000};
                    new_point_Y_r <= new_point_Y_r;
                end
                1: begin
                    new_point_X_r <= {new_point_X_r[9:5], PT_XY};
                    new_point_Y_r <= new_point_Y_r;
                end
                2: begin
                    new_point_X_r <= new_point_X_r;
                    new_point_Y_r <= {PT_XY, 5'b00000};
                end
                3: begin
                    new_point_X_r <= new_point_X_r;
                    new_point_Y_r <= {new_point_Y_r[9:5], PT_XY};
                end
                default: begin
                    new_point_X_r <= new_point_X_r;
                    new_point_Y_r <= new_point_Y_r;
                end 
            endcase
        end
        default: begin
            new_point_X_r <= new_point_X_r;
            new_point_Y_r <= new_point_Y_r;
        end
    endcase
end
// Reset list
generate
for ( j = 0 ; j < MAX_POINTS+1; j = j + 1) begin
    always @(posedge CLK or posedge RST) begin
        if(RST) begin
            points_X_r[j] <= 0;
            points_Y_r[j] <= 0;
        end
        else begin
            points_X_r[j] <= points_X_w[j];
            points_Y_r[j] <= points_Y_w[j];
        end
    end
end
endgenerate

always @(posedge CLK or posedge RST) begin
    if(RST) begin
        centroid_X_r <= 0;
        centroid_Y_r <= 0;
    end
    else begin
        centroid_X_r <= centroid_X_w[16:7];
        centroid_Y_r <= centroid_Y_w[16:7];
    end
end

always @(posedge CLK or posedge RST) begin
    if(RST) begin
        num_drop_r <= 0;
        out_cnt_r <= 0;
    end
    else begin
        case(cstate)
            S_TRANVERSE: num_drop_r <= idx_tranverse_r != idx_upper_r ? num_drop_r + 1 : num_drop_r; 
            S_DROP_NEWP: num_drop_r <= MAX_DROP+1;
            S_READ_PT : num_drop_r <= 0;
            default: num_drop_r <= num_drop_r;
        endcase

        case(cstate)
            S_TRANVERSE: out_cnt_r <= {num_drop_r, 1'b0}; 
            S_DROP_NEWP: out_cnt_r <= 2;
            S_OUTPUT : out_cnt_r <= out_cnt_r - 1;
            default: out_cnt_r <= out_cnt_r;
        endcase
    end
end

generate
for ( j = 0 ; j < MAX_DROP; j = j + 1) begin
    always @(posedge CLK or posedge RST) begin
        if(RST) begin
            drop_X_r[j] <= 0;
            drop_Y_r[j] <= 0;
        end
        else begin
            drop_X_r[j] <= drop_X_w[j];
            drop_Y_r[j] <= drop_Y_w[j];
        end
    end
end
endgenerate

always @(posedge CLK or posedge RST) begin
    if(RST) begin
        min_distance_r <= 20'b1111_1111_1111_1111_1111;
        idx_closest_point_r <= 0;
        idx_upper_r <= 0;
        idx_lower_r <= 0;
        idx_tranverse_r <= 0;
    end
    else begin
        case(cstate)
            S_FIND_SMALLEST: min_distance_r <= min_distance_r > distance_to_P_w ? distance_to_P_w : min_distance_r;
            default: min_distance_r <=20'b1111_1111_1111_1111_1111;
        endcase
        case(cstate)
            S_FIND_SMALLEST: idx_closest_point_r <= min_distance_r > distance_to_P_w ? generic_cnt : idx_closest_point_r;
            default: idx_closest_point_r <= idx_closest_point_r;
        endcase
        case(cstate)
            S_FIND_SMALLEST: begin
                idx_upper_r <= min_distance_r > distance_to_P_w ? generic_cnt : idx_closest_point_r;
                idx_lower_r <= min_distance_r > distance_to_P_w ? generic_cnt : idx_closest_point_r;
            end
            S_FIND_UPPER:begin
                idx_upper_r <= orientation_w[20] ? idx_upper_r : (idx_upper_r+1)%num_points_r;
                idx_lower_r <= idx_lower_r;
            end
            S_FIND_LOWER:begin
                idx_upper_r <= idx_upper_r;
                idx_lower_r <=  orientation_w > 0 ? idx_lower_r : (num_points_r + idx_lower_r - 1 )%num_points_r;
            end
            default: begin
                idx_upper_r <= idx_upper_r;
                idx_lower_r <= idx_lower_r;
            end
        endcase

        case(cstate)
            S_FIND_LOWER: idx_tranverse_r <= (idx_lower_r+1)%num_points_r;
            S_TRANVERSE: idx_tranverse_r <= (idx_tranverse_r+1)%num_points_r;
            default: idx_tranverse_r <= idx_tranverse_r;
        endcase
    end
end

endmodule

