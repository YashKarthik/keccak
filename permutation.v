`default_nettype none

module permutation (
    input wire i_clk,
    input reg[1599:0] i_sponge,
    input wire i_trigger,
    output reg[1599:0] o_sponge,
    output wire o_ready
);
    reg[1599:0] sponge;
    reg[2:0] curr_state = READY;
    reg[4:0] rounds = 0;

    localparam
        READY        = 3'b000,
        STEP_THETA  = 3'b001,
        STEP_RHO    = 3'b010,
        STEP_PI     = 3'b011,
        STEP_CHI    = 3'b100,
        STEP_IOTA   = 3'b101;

    localparam [63:0] RC [24] = {
        64'h0000000000000001,
        64'h0000000000008082,
        64'h800000000000808A,
        64'h8000000080008000,
        64'h000000000000808B,
        64'h0000000080000001,
        64'h8000000080008081,
        64'h8000000000008009,
        64'h000000000000008A,
        64'h0000000000000088,
        64'h0000000080008009,
        64'h000000008000000A,
        64'h000000008000808B,
        64'h800000000000008B,
        64'h8000000000008089,
        64'h8000000000008003,
        64'h8000000000008002,
        64'h8000000000000080,
        64'h000000000000800A,
        64'h800000008000000A,
        64'h8000000080008081,
        64'h8000000000008080,
        64'h0000000080000001,
        64'h8000000080008008
    };

    assign o_ready = (curr_state == READY) ? 1 : 0;

    always @ (posedge i_clk) begin
        case (curr_state)
            READY:begin
                o_sponge <= sponge;
                if (i_trigger) begin
                    sponge <= i_sponge;
                    curr_state <= STEP_THETA;
                end
            end

            STEP_THETA: begin
                rounds <= rounds + 1;
                // imple theta
            end

            STEP_IOTA: begin
                curr_state <= (rounds == 24) ? READY : STEP_THETA;
                sponge[63:0] <= sponge[63:0] ^ RC[rounds - 1];
            end

            default: o_sponge <= 0;
        endcase
    end
endmodule
