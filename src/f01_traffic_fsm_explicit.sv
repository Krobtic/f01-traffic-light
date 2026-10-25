module f01_traffic_fsm_explicit #(
    parameter int PHASE_TICKS = 4,
    parameter int NIGHT_TICKS = 2
)(
    input logic clk, input logic rst_n, input logic ena,
    input logic night_mode, output logic [7:0] uo_out
);
    typedef enum logic [1:0] {
        S_NS_G=2'd0, S_NS_Y=2'd1, S_EW_G=2'd2, S_EW_Y=2'd3
    } state_t;

    localparam int PW=(PHASE_TICKS<=1)?1:$clog2(PHASE_TICKS);
    localparam int NW=(NIGHT_TICKS<=1)?1:$clog2(NIGHT_TICKS);

    state_t state,next;
    logic [PW-1:0] pc;
    logic [NW-1:0] nc;
    logic night_phase;

    always_comb begin
        next=state;
        if (!night_mode) begin
            case(state)
                S_NS_G: if(pc==PHASE_TICKS-1) next=S_NS_Y;
                S_NS_Y: if(pc==PHASE_TICKS-1) next=S_EW_G;
                S_EW_G: if(pc==PHASE_TICKS-1) next=S_EW_Y;
                S_EW_Y: if(pc==PHASE_TICKS-1) next=S_NS_G;
                default: next=S_NS_G;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state<=S_NS_G; pc<='0; nc<='0; night_phase<=1'b0;
        end else if(ena) begin
            state<=next;
            if(night_mode) begin
                pc<='0;
                if(nc==NIGHT_TICKS-1) begin
                    nc<='0;
                    night_phase<=~night_phase;
                end else nc<=nc+1'b1;
            end else begin
                nc<='0; night_phase<=1'b0;
                pc <= (state!=next || pc==PHASE_TICKS-1)?'0:pc+1'b1;
            end
        end
    end

    always_comb begin
        uo_out='0;
        if(night_mode) begin
            if(night_phase) begin
                uo_out[2:0]=3'b010;
                uo_out[5:3]=3'b010;
            end
        end else begin
            case(state)
                S_NS_G: begin uo_out[2:0]=3'b001; uo_out[5:3]=3'b100; end
                S_NS_Y: begin uo_out[2:0]=3'b010; uo_out[5:3]=3'b100; end
                S_EW_G: begin uo_out[2:0]=3'b100; uo_out[5:3]=3'b001; end
                S_EW_Y: begin uo_out[2:0]=3'b100; uo_out[5:3]=3'b010; end
                default: begin uo_out[2:0]=3'b100; uo_out[5:3]=3'b100; end
            endcase
        end
        uo_out[7:6]=state;
    end
endmodule
