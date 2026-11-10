//=================================================================
// Somador FP32 simples (combinacional)
//  - arredondamento por truncamento
//  - subnormais tratados como zero (flush-to-zero)
//  - overflow satura em +/-Inf; NaN/Inf de entrada nao tratados
//=================================================================

module fp32_add (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] z
);

    //==========================================================
    //  Internos
    //==========================================================
    logic        a_ge, sub, found;
    logic [31:0] big_r, small_r;
    logic [7:0]  eb, es, d;
    logic [23:0] mb, ms0, m;
    logic [26:0] mb_x, ms_x, sum_n;
    logic [27:0] sum;
    logic signed [9:0] e;
    integer i, lz;

    //==========================================================
    //  Combinacional
    //==========================================================
    always_comb begin
        a_ge  = (a[30:0] >= b[30:0]);
        big_r   = a_ge ? a : b;
        small_r = a_ge ? b : a;
        eb    = big_r[30:23];
        es    = small_r[30:23];
        mb    = (eb == 0) ? 24'd0 : {1'b1, big_r[22:0]};
        ms0   = (es == 0) ? 24'd0 : {1'b1, small_r[22:0]};
        d     = eb - es;
        mb_x  = {mb,  3'b000};
        ms_x  = ({ms0, 3'b000}) >> d;
        sub   = big_r[31] ^ small_r[31];
        sum   = sub ? ({1'b0, mb_x} - {1'b0, ms_x})
                    : ({1'b0, mb_x} + {1'b0, ms_x});

        // normalizacao
        found = 1'b0;
        lz    = 0;
        for (i = 26; i >= 0; i = i - 1) begin
            if (sum[i]) found = 1'b1;
            else if (!found) lz = lz + 1;
        end

        sum_n = sum[26:0] << lz;
        m     = sum[27] ? sum[27:4] : sum_n[26:3];
        e     = sum[27] ? $signed({2'b00, eb}) + 10'sd1
                        : $signed({2'b00, eb}) - lz;

        if (sum == 28'd0 || e <= 0) z = 32'd0;                        // zero / underflow
        else if (e >= 255)          z = {big_r[31], 8'hFF, 23'd0};      // overflow -> Inf
        else                        z = {big_r[31], e[7:0], m[22:0]};
    end
endmodule