module f01_traffic_fsm #(
    parameter int PHASE_TICKS = 4,
    parameter int NIGHT_TICKS = 2
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       ena,
    input  logic       night_mode,
    output logic [7:0] uo_out
);
    localparam int PW = (PHASE_TICKS <= 1) ? 1 : $clog2(PHASE_TICKS);
    localparam int NW = (NIGHT_TICKS <= 1) ? 1 : $clog2(NIGHT_TICKS);

    typedef enum logic [1:0] {
        NS_GREEN  = 2'd0,
        NS_YELLOW = 2'd1,
        EW_GREEN  = 2'd2,
        EW_YELLOW = 2'd3
    } state_t;

    state_t state, next_state;
    logic [PW-1:0] phase_cnt;
    logic [NW-1:0] night_cnt;
    logic night_phase;

    always_comb begin
        next_state = state;

        if (night_mode) begin
            // Normal traffic phase is held while night mode is active.
            next_state = state;
        end else begin
            case (state)
                NS_GREEN:
                    if (phase_cnt == PHASE_TICKS-1) next_state = NS_YELLOW;
                NS_YELLOW:
                    if (phase_cnt == PHASE_TICKS-1) next_state = EW_GREEN;
                EW_GREEN:
                    if (phase_cnt == PHASE_TICKS-1) next_state = EW_YELLOW;
                EW_YELLOW:
                    if (phase_cnt == PHASE_TICKS-1) next_state = NS_GREEN;
                default:
                    next_state = NS_GREEN;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state      <= NS_GREEN;
            phase_cnt  <= '0;
            night_cnt  <= '0;
            night_phase <= 1'b0;
        end else if (ena) begin
            state <= next_state;

            if (night_mode) begin
                phase_cnt <= '0;
                if (night_cnt == NIGHT_TICKS-1) begin
                    night_cnt   <= '0;
                    night_phase <= ~night_phase;
                end else begin
                    night_cnt <= night_cnt + 1'b1;
                end
            end else begin
                night_cnt   <= '0;
                night_phase <= 1'b0;
                if (state != next_state)
                    phase_cnt <= '0;
                else if (phase_cnt == PHASE_TICKS-1)
                    phase_cnt <= '0;
                else
                    phase_cnt <= phase_cnt + 1'b1;
            end
        end
    end

    always_comb begin
        uo_out = '0;

        if (night_mode) begin
            // Flashing-yellow overlay. Both directions are yellow during
            // the visible half-cycle and off during the dark half-cycle.
            if (night_phase) begin
                uo_out[2:0] = 3'b010;
                uo_out[5:3] = 3'b010;
            end
        end else begin
            case (state)
                NS_GREEN: begin
                    uo_out[2:0] = 3'b001;
                    uo_out[5:3] = 3'b100;
                end
                NS_YELLOW: begin
                    uo_out[2:0] = 3'b010;
                    uo_out[5:3] = 3'b100;
                end
                EW_GREEN: begin
                    uo_out[2:0] = 3'b100;
                    uo_out[5:3] = 3'b001;
                end
                EW_YELLOW: begin
                    uo_out[2:0] = 3'b100;
                    uo_out[5:3] = 3'b010;
                end
                default: begin
                    uo_out[2:0] = 3'b100;
                    uo_out[5:3] = 3'b100;
                end
            endcase
        end

        // 2-bit state code is valid for the four normal traffic phases.
        uo_out[7:6] = state;
    end
endmodule
