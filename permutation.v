`default_nettype none

module permutation (
    input wire i_clk,
    input reg [1599:0] i_sponge,
    input wire i_trigger,
    output reg [1599:0] o_sponge,
    output wire o_ready
);
    reg [1599:0] sponge;
    reg [1599:0] sponge_temp;
    reg [63:0] col_paritys [5];
    reg [63:0] col_deltas [5];
    reg [2:0] curr_state = READY;
    reg [4:0] rounds = 0;
    reg [6:0] i;
    reg [6:0] j;

    localparam
        READY        = 3'b000,
        STEP_THETA   = 3'b001,
        STEP_RHO_PI  = 3'b010,
        STEP_CHI     = 3'b100,
        STEP_IOTA    = 3'b101,
        STEP_COLS    = 3'b110,
        STEP_DELTA   = 3'b111;

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

    localparam [5:0] rot_offset [5][5] = {
        {0 , 1 , 62, 28, 27},
        {36, 44, 6 , 55, 20},
        {3 , 10, 43, 25, 39},
        {41, 45, 15, 21, 8},
        {18, 2 , 61, 56, 14}
    };

    function static [63:0] rot_lane(input reg [63:0] col_parity, input reg [5:0] offset);
        begin
            return (col_parity << offset) | (col_parity >> (64 - offset));
        end
    endfunction

    assign o_ready = (curr_state == READY) ? 1 : 0;

    always @ (posedge i_clk) begin
        case (curr_state)

            READY:begin
                o_sponge <= sponge;
                if (i_trigger) begin
                    sponge <= i_sponge;
                    curr_state <= STEP_COLS;
                end
            end

            STEP_COLS: begin
                for (i=0; i < 5; i = i + 1) begin
                    col_paritys[i[2:0]] <= sponge[i*64 +: 64]
                    ^ sponge[i*64 + 64*5 +: 64]
                    ^ sponge[i*64 + 64*10 +: 64]
                    ^ sponge[i*64 + 64*15 +: 64]
                    ^ sponge[i*64 + 64*20 +: 64];
                end

                curr_state <= STEP_DELTA;
            end

            STEP_DELTA: begin
                for (i=0; i < 5; i = i + 1) begin
                    col_deltas[i] <= col_paritys[(i == 0) ? 4 : (i - 1)] ^ rot_lane(col_paritys[(i + 1) % 5], 1);
                end

                curr_state <= STEP_THETA;
            end

            STEP_THETA: begin
                rounds <= rounds + 1;
                curr_state <= STEP_RHO_PI;

                for (j = 0; j < 5; j = j + 1) begin // row (up-down)
                    for (i = 0; i < 5; i = i + 1) begin // col (left-right)
                        sponge[i*64 + 64*5*j +: 64] <= sponge[i*64 + 64*5*j +: 64] ^ col_deltas[i];
                    end
                end
            end

            // x, i: column
            // y, j: row
            STEP_RHO_PI: begin
                for (j = 0; j < 5; j = j + 1) begin // row (up-down)
                    for (i = 0; i < 5; i = i + 1) begin // col (left-right)
                        sponge_temp[j*64 + 64*5*(2*i+3*j) +: 64] <= rot_lane(sponge[i*64 + 64*5*j +: 64], rot_offset[j][i]);
                    end
                end

                curr_state <= STEP_CHI;
            end

            STEP_CHI: begin
                for (j = 0; j < 5; j = j + 1) begin // row (up-down)
                    for (i = 0; i < 5; i = i + 1) begin // col (left-right)
                        sponge[i*64 + 64*5*j +: 64] <= sponge_temp[i*64 + 64*5*j +: 64] ^ ((~sponge_temp[(i+1)*64 + 64*5*j +: 64]) & sponge_temp[(i+2)*64 + 64*5*j +: 64]);
                    end
                end

                curr_state <= STEP_IOTA;
            end

            STEP_IOTA: begin
                curr_state <= (rounds == 24) ? READY : STEP_COLS;
                sponge[63:0] <= sponge[63:0] ^ RC[rounds - 1];
            end

            default: o_sponge <= 0;
        endcase
    end
endmodule
