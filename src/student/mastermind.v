module mastermind(
    input clk,
    input rst,
    input enterA,
    input enterB,
    input [2:0] letterIn,
    input sp_mode,
    input rng_bit,
    output reg [7:0] LEDX,
    output reg [6:0] SSD3,
    output reg [6:0] SSD2,
    output reg [6:0] SSD1,
    output reg [6:0] SSD0 
); 
        
    // 1. STATE DEFINITIONS
    parameter S0_START            = 4'b0000;
    parameter S1_SHOW_SCORE       = 4'b0001;
    parameter S2_SHOW_CODEMAKER   = 4'b0010;
    parameter S3_CM_GET_LETTERS   = 4'b0011;
    parameter S4_SHOW_CODEBREAKER = 4'b0100;
    parameter S5_SHOW_LIVES       = 4'b0101;
    parameter S6_CB_GET_LETTERS   = 4'b0110;
    parameter S7_EVAL_GUESS       = 4'b0111;
    parameter S8_SHOW_CORRECT     = 4'b1000;
    parameter S9_SHOW_SCORE_END   = 4'b1001;
    parameter S10_CHECK_GAME_END  = 4'b1010;
    parameter S11_SP_GENERATE     = 4'b1011;
    parameter S12_SP_SHOW_READY   = 4'b1100;

    // 2. INTERNAL REGISTERS
    reg [3:0] state, next_state;
    reg cm_is_A;
    reg [2:0] secret [0:3];
    reg [2:0] guess  [0:3];
    reg [2:0] enterCount;
    reg [1:0] lives;
    reg [1:0] scoreA;
    reg [1:0] scoreB;
    reg [14:0] timer;
    reg cm_enter;
    reg cb_enter;
    reg is_sp_mode;
    reg [2:0] rng_count;
    reg ignore_enter;
    reg cm_done;
    reg [3:0] prev_state;

    // 3. PRIMITIVE DECODING REGISTERS
    reg [6:0] s0_ssd, s1_ssd, s2_ssd, s3_ssd;
    reg [6:0] g0_ssd, g1_ssd, g2_ssd, g3_ssd;

    // Debouncer Mux
    always @(*) begin
        if (cm_is_A) begin
            cm_enter = enterA;
            cb_enter = enterB;
        end else begin
            cm_enter = enterB;
            cb_enter = enterA;
        end
    end

    // 4. STATE REGISTERS
    always @(posedge clk or negedge rst) begin
        if (!rst)
            state <= S0_START;
        else
            state <= next_state;
    end
    
    // 5. NEXT STATE LOGIC
    always @(*) begin
        next_state = state;
        case (state)
            S0_START: begin
                if (!ignore_enter) begin
                    if (sp_mode && enterA) next_state = S11_SP_GENERATE;
                    else if (enterA || enterB) next_state = S1_SHOW_SCORE;
                end
            end
            S11_SP_GENERATE: if (rng_count == 3'b100) next_state = S12_SP_SHOW_READY;
            S12_SP_SHOW_READY: if (timer >= 15'd100) next_state = S5_SHOW_LIVES;
            S1_SHOW_SCORE: begin
                if (timer >= 15'd100) next_state = S2_SHOW_CODEMAKER;
            end
            S2_SHOW_CODEMAKER: if (timer >= 15'd100) next_state = S3_CM_GET_LETTERS;
            S3_CM_GET_LETTERS: if (cm_done && timer >= 15'd100) next_state = S4_SHOW_CODEBREAKER;
            S4_SHOW_CODEBREAKER: if (timer >= 15'd100) next_state = S5_SHOW_LIVES;
            S5_SHOW_LIVES: if (timer >= 15'd100) next_state = S6_CB_GET_LETTERS;
            S6_CB_GET_LETTERS: if (enterCount == 3'b100 && timer == 0) next_state = S7_EVAL_GUESS;
            S7_EVAL_GUESS: begin
                if (is_sp_mode) begin
                    if (enterA) begin
                        if (all_correct || lives == 2'b01) next_state = S8_SHOW_CORRECT;
                        else next_state = S5_SHOW_LIVES;
                    end
                end else begin
                    if (cb_enter) begin
                        if (all_correct || lives == 2'b01) next_state = S8_SHOW_CORRECT;
                        else next_state = S5_SHOW_LIVES;
                    end
                end
            end
            S8_SHOW_CORRECT: if (timer >= 15'd100) next_state = S9_SHOW_SCORE_END;
            S9_SHOW_SCORE_END: begin
                if (timer >= 15'd100) begin
                    if (is_sp_mode) next_state = S0_START;
                    else next_state = S10_CHECK_GAME_END;
                end
            end
            S10_CHECK_GAME_END: begin
                if (scoreA == 2'b10 || scoreB == 2'b10) next_state = S0_START;
                else next_state = S2_SHOW_CODEMAKER;
            end
            default: next_state = S0_START;
        endcase
    end

    // 6. SEQUENTIAL GAME LOGIC
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin
            cm_done <= 1'b0;
            ignore_enter <= 1'b1;
            prev_state <= S0_START;
            cm_is_A <= 1'b0;
            scoreA <= 2'b00;
            scoreB <= 2'b00;
            lives <= 2'b11;
            enterCount <= 3'b000;
            timer <= 15'd0;
            is_sp_mode <= 1'b0;
            all_correct <= 1'b0;
            rng_count <= 3'b000;
            secret[0] <= 3'b000; secret[1] <= 3'b000; secret[2] <= 3'b000; secret[3] <= 3'b000;
            guess[0] <= 3'b000; guess[1] <= 3'b000; guess[2] <= 3'b000; guess[3] <= 3'b000;
        end else begin
            if (ignore_enter && (enterA || enterB))
                ignore_enter <= 1'b0;
            prev_state <= state;
            case (state)
                S0_START: begin
                    cm_done <= 1'b0;
                    timer <= 15'd0;
                    enterCount <= 3'b000;
                    if (sp_mode && enterA) begin
                        is_sp_mode <= 1'b1; cm_is_A <= 1'b0; scoreA <= 2'b00; scoreB <= 2'b00; lives <= 2'b11; rng_count <= 3'b000;
                    end else if (enterA || enterB) begin
                        is_sp_mode <= 1'b0;
                        if (enterA) cm_is_A <= 1'b1; else if (enterB) cm_is_A <= 1'b0;
                        scoreA <= 2'b00; scoreB <= 2'b00; lives <= 2'b11;
                    end
                end
                S11_SP_GENERATE: begin
                    if (rng_count < 3'b100) begin
                        case (rng_count)
                            3'b000: secret[0] <= {secret[0][1:0], rng_bit};
                            3'b001: secret[1] <= {secret[1][1:0], rng_bit};
                            3'b010: secret[2] <= {secret[2][1:0], rng_bit};
                            3'b011: secret[3] <= {secret[3][1:0], rng_bit};
                        endcase
                        if (secret[rng_count][1:0] == 2'b11 || (rng_count > 3'b000 && secret[rng_count][1:0] != 2'b00))
                            rng_count <= rng_count + 3'b001;
                    end
                end
                S12_SP_SHOW_READY: if (timer < 15'd100) timer <= timer + 15'd1; else timer <= 15'd0;
                S1_SHOW_SCORE: if (timer < 15'd100) timer <= timer + 15'd1; else timer <= 15'd0;
                S2_SHOW_CODEMAKER: begin
                    cm_done <= 1'b0; enterCount <= 3'b000;
                    if (timer < 15'd100) timer <= timer + 15'd1; else timer <= 15'd0;
                end
                S3_CM_GET_LETTERS: begin
                    if (timer > 0) begin
                        if (cm_done) begin
                             if (timer < 15'd100) timer <= timer + 15'd1; else timer <= 15'd0;
                        end else begin
                             if (timer < 15'd25) timer <= timer + 15'd1; else timer <= 15'd0;
                        end
                    end else begin
                        if (!cm_done && cm_enter && letterIn != 3'b000) begin
                            secret[enterCount] <= letterIn;
                            enterCount <= enterCount + 3'b001;
                            timer <= 15'd1; 
                            if (enterCount == 3'b011) cm_done <= 1'b1;
                        end
                    end
                end
                S4_SHOW_CODEBREAKER: begin
                    enterCount <= 3'b000;
                    if (timer < 15'd100) timer <= timer + 15'd1; else timer <= 15'd0;
                end
                S5_SHOW_LIVES: begin
                    enterCount <= 3'b000;
                    guess[0] <= 3'b000;
                    guess[1] <= 3'b000;
                    guess[2] <= 3'b000;
                    guess[3] <= 3'b000;
                    if (timer < 15'd100) timer <= timer + 15'd1; else timer <= 15'd0;
                end
                S6_CB_GET_LETTERS: begin
                    if (timer > 0) begin
                        if (timer < 15'd25) timer <= timer + 15'd1; else timer <= 15'd0;
                    end else begin
                         if (is_sp_mode) begin
                            if (enterA && enterCount < 3'b100 && letterIn != 3'b000) begin
                                guess[enterCount] <= letterIn; enterCount <= enterCount + 3'b001; timer <= 15'd1;
                            end
                        end else begin
                            if (cb_enter && enterCount < 3'b100 && letterIn != 3'b000) begin
                                guess[enterCount] <= letterIn; enterCount <= enterCount + 3'b001; timer <= 15'd1;
                            end
                        end
                    end
                end
                S7_EVAL_GUESS: begin
                    all_correct <= all_correct_next;
                    if (is_sp_mode) begin
                        if (enterA && !all_correct && lives > 2'b00) lives <= lives - 2'b01;
                    end else begin
                        if (cb_enter && !all_correct && lives > 2'b00) lives <= lives - 2'b01;
                    end
                end
                S8_SHOW_CORRECT: if (timer < 15'd100) timer <= timer + 15'd1; else timer <= 15'd0;
                S9_SHOW_SCORE_END: begin
                    if (prev_state != S9_SHOW_SCORE_END) begin
                        // Just entered this state - update scores now
                        if (!is_sp_mode) begin
                            if (all_correct) begin
                                if (cm_is_A) begin
                                    scoreB <= scoreB + 2'b01;
                                end else begin
                                    scoreA <= scoreA + 2'b01;
                                end
                            end else begin
                                if (cm_is_A) begin
                                    scoreA <= scoreA + 2'b01;
                                end else begin
                                    scoreB <= scoreB + 2'b01;
                                end
                            end
                        end
                    end
                    if (timer < 15'd100) timer <= timer + 15'd1;
                    else begin
                        timer <= 15'd0;
                        cm_is_A <= ~cm_is_A;
                        lives <= 2'b11;
                    end
                end
                S10_CHECK_GAME_END: begin
                    if (timer < 15'd49) timer <= timer + 15'd1; else timer <= 15'd0;
                end
            endcase
        end
    end

    // 7. PRIMITIVE DECODING BLOCK (IF-ELSE REPLACEMENT)
    always @(*) begin
        // Secret 0
        if (secret[0] == 3'b000) s0_ssd = 7'b1000000; // -
        else if (secret[0] == 3'b001) s0_ssd = 7'b1110111; // A
        else if (secret[0] == 3'b010) s0_ssd = 7'b0111001; // C
        else if (secret[0] == 3'b011) s0_ssd = 7'b1111001; // E
        else if (secret[0] == 3'b100) s0_ssd = 7'b1110001; // F
        else if (secret[0] == 3'b101) s0_ssd = 7'b1110110; // H
        else if (secret[0] == 3'b110) s0_ssd = 7'b0111000; // L
        else s0_ssd = 7'b0111110; // U

        // Secret 1
        if (secret[1] == 3'b000) s1_ssd = 7'b1000000;
        else if (secret[1] == 3'b001) s1_ssd = 7'b1110111;
        else if (secret[1] == 3'b010) s1_ssd = 7'b0111001;
        else if (secret[1] == 3'b011) s1_ssd = 7'b1111001;
        else if (secret[1] == 3'b100) s1_ssd = 7'b1110001;
        else if (secret[1] == 3'b101) s1_ssd = 7'b1110110;
        else if (secret[1] == 3'b110) s1_ssd = 7'b0111000;
        else s1_ssd = 7'b0111110;

        // Secret 2
        if (secret[2] == 3'b000) s2_ssd = 7'b1000000;
        else if (secret[2] == 3'b001) s2_ssd = 7'b1110111;
        else if (secret[2] == 3'b010) s2_ssd = 7'b0111001;
        else if (secret[2] == 3'b011) s2_ssd = 7'b1111001;
        else if (secret[2] == 3'b100) s2_ssd = 7'b1110001;
        else if (secret[2] == 3'b101) s2_ssd = 7'b1110110;
        else if (secret[2] == 3'b110) s2_ssd = 7'b0111000;
        else s2_ssd = 7'b0111110;

        // Secret 3
        if (secret[3] == 3'b000) s3_ssd = 7'b1000000;
        else if (secret[3] == 3'b001) s3_ssd = 7'b1110111;
        else if (secret[3] == 3'b010) s3_ssd = 7'b0111001;
        else if (secret[3] == 3'b011) s3_ssd = 7'b1111001;
        else if (secret[3] == 3'b100) s3_ssd = 7'b1110001;
        else if (secret[3] == 3'b101) s3_ssd = 7'b1110110;
        else if (secret[3] == 3'b110) s3_ssd = 7'b0111000;
        else s3_ssd = 7'b0111110;

        // Guess 0
        if (guess[0] == 3'b000) g0_ssd = 7'b1000000;
        else if (guess[0] == 3'b001) g0_ssd = 7'b1110111;
        else if (guess[0] == 3'b010) g0_ssd = 7'b0111001;
        else if (guess[0] == 3'b011) g0_ssd = 7'b1111001;
        else if (guess[0] == 3'b100) g0_ssd = 7'b1110001;
        else if (guess[0] == 3'b101) g0_ssd = 7'b1110110;
        else if (guess[0] == 3'b110) g0_ssd = 7'b0111000;
        else g0_ssd = 7'b0111110;

        // Guess 1
        if (guess[1] == 3'b000) g1_ssd = 7'b1000000;
        else if (guess[1] == 3'b001) g1_ssd = 7'b1110111;
        else if (guess[1] == 3'b010) g1_ssd = 7'b0111001;
        else if (guess[1] == 3'b011) g1_ssd = 7'b1111001;
        else if (guess[1] == 3'b100) g1_ssd = 7'b1110001;
        else if (guess[1] == 3'b101) g1_ssd = 7'b1110110;
        else if (guess[1] == 3'b110) g1_ssd = 7'b0111000;
        else g1_ssd = 7'b0111110;

        // Guess 2
        if (guess[2] == 3'b000) g2_ssd = 7'b1000000;
        else if (guess[2] == 3'b001) g2_ssd = 7'b1110111;
        else if (guess[2] == 3'b010) g2_ssd = 7'b0111001;
        else if (guess[2] == 3'b011) g2_ssd = 7'b1111001;
        else if (guess[2] == 3'b100) g2_ssd = 7'b1110001;
        else if (guess[2] == 3'b101) g2_ssd = 7'b1110110;
        else if (guess[2] == 3'b110) g2_ssd = 7'b0111000;
        else g2_ssd = 7'b0111110;

        // Guess 3
        if (guess[3] == 3'b000) g3_ssd = 7'b1000000;
        else if (guess[3] == 3'b001) g3_ssd = 7'b1110111;
        else if (guess[3] == 3'b010) g3_ssd = 7'b0111001;
        else if (guess[3] == 3'b011) g3_ssd = 7'b1111001;
        else if (guess[3] == 3'b100) g3_ssd = 7'b1110001;
        else if (guess[3] == 3'b101) g3_ssd = 7'b1110110;
        else if (guess[3] == 3'b110) g3_ssd = 7'b0111000;
        else g3_ssd = 7'b0111110;
    end

    // 8. OUTPUT LOGIC (SSD + LED)
    reg [1:0] ledpair0, ledpair1, ledpair2, ledpair3;
    reg all_correct;
    reg all_correct_next;
    always @(*) begin
        // LED LOGIC
        all_correct_next = 1'b0;
        ledpair0=0; ledpair1=0; ledpair2=0; ledpair3=0;
        
        if (state == S7_EVAL_GUESS) begin
            all_correct_next = 1'b1;
            if (guess[0] == secret[0]) ledpair0 = 2'b11;
            else begin all_correct_next=1'b0; if((guess[0]==secret[1])||(guess[0]==secret[2])||(guess[0]==secret[3])) ledpair0=2'b01; end
            
            if (guess[1] == secret[1]) ledpair1 = 2'b11;
            else begin all_correct_next=1'b0; if((guess[1]==secret[0])||(guess[1]==secret[2])||(guess[1]==secret[3])) ledpair1=2'b01; end

            if (guess[2] == secret[2]) ledpair2 = 2'b11;
            else begin all_correct_next=1'b0; if((guess[2]==secret[0])||(guess[2]==secret[1])||(guess[2]==secret[3])) ledpair2=2'b01; end

            if (guess[3] == secret[3]) ledpair3 = 2'b11;
            else begin all_correct_next=1'b0; if((guess[3]==secret[0])||(guess[3]==secret[1])||(guess[3]==secret[2])) ledpair3=2'b01; end
            
            LEDX = {ledpair0, ledpair1, ledpair2, ledpair3};
        end
        else if (state == S9_SHOW_SCORE_END && (scoreA == 2'b10 || scoreB == 2'b10)) begin
            if (timer < 15'd24 || (timer > 15'd49 && timer < 15'd75)) begin
                LEDX = {8'b10101010};
            end
            else begin
                LEDX = {8'b01010101};
            end
        end else begin
            LEDX = {8'b00000000}; 
        end

        // SSD LOGIC (Primitive Assignments)
        SSD3=0; SSD2=0; SSD1=0; SSD0=0;
        case (state)
            S0_START: begin SSD2=7'b1110111; SSD1=7'b1000000; SSD0=7'b1111100; end
            S11_SP_GENERATE: begin SSD2=7'b0; SSD1=7'b0111101; SSD0=7'b1101110; end
            S12_SP_SHOW_READY: begin SSD2=7'b1111101; SSD1=7'b0111111; SSD0=7'b1000000; end
            S1_SHOW_SCORE: begin
                if (scoreA==0) SSD2=7'b0111111; else if (scoreA==1) SSD2=7'b0000110; else SSD2=7'b1011011;
                SSD1=7'b1000000;
                if (scoreB==0) SSD0=7'b0111111; else if (scoreB==1) SSD0=7'b0000110; else SSD0=7'b1011011;
            end
            S2_SHOW_CODEMAKER: begin SSD2=7'b1110011; SSD1=7'b1000000; if(cm_is_A) SSD0=7'b1110111; else SSD0=7'b1111100; end
            
            S3_CM_GET_LETTERS: begin
                SSD3=s0_ssd; SSD2=s1_ssd; SSD1=s2_ssd; SSD0=s3_ssd;
                if (enterCount > 3'b001) begin SSD3=7'b1000000; end
                if (enterCount > 3'b010) begin SSD2=7'b1000000; end
                if (enterCount > 3'b011) begin SSD1=7'b1000000; end
                if (enterCount < 3'b001) begin SSD3=7'b0000000; end
                if (enterCount <= 3'b001) begin SSD2=7'b0000000; end
                if (enterCount < 3'b011) begin SSD1=7'b0000000; end
                if (enterCount < 3'b100) begin SSD0=7'b0000000; end
            end

            S4_SHOW_CODEBREAKER: begin SSD2=7'b1110011; SSD1=7'b1000000; if(cm_is_A) SSD0=7'b1111100; else SSD0=7'b1110111; end
            S5_SHOW_LIVES: begin SSD2=7'b0111000; SSD1=7'b1000000; if(lives==3) SSD0=7'b1001111; else if(lives==2) SSD0=7'b1011011; else if(lives==1) SSD0=7'b0000110; else SSD0=7'b0111111; end
            
            S6_CB_GET_LETTERS: begin
                SSD3=g0_ssd; SSD2=g1_ssd; SSD1=g2_ssd; SSD0=g3_ssd;
                if (enterCount < 3'b001) begin SSD3=7'b0000000; end
                if (enterCount <= 3'b001) begin SSD2=7'b0000000; end
                if (enterCount < 3'b011) begin SSD1=7'b0000000; end
                if (enterCount < 3'b100) begin SSD0=7'b0000000; end
            end

            S7_EVAL_GUESS: begin SSD3=g0_ssd; SSD2=g1_ssd; SSD1=g2_ssd; SSD0=g3_ssd; end
            S8_SHOW_CORRECT: begin SSD3=s0_ssd; SSD2=s1_ssd; SSD1=s2_ssd; SSD0=s3_ssd; end
            S9_SHOW_SCORE_END: begin
                if (is_sp_mode) begin
                    if(all_correct) begin SSD2=7'b0111110; SSD1=7'b0110000; SSD0=7'b0110111; end
                    else begin SSD2=7'b0111000; SSD1=7'b0111111; SSD0=7'b0; end
                end else begin
                    if(scoreA==0) SSD2=7'b0111111; else if(scoreA==1) SSD2=7'b0000110; else SSD2=7'b1011011;
                    SSD1=7'b1000000;
                    if(scoreB==0) SSD0=7'b0111111; else if(scoreB==1) SSD0=7'b0000110; else SSD0=7'b1011011;
                end
            end
            S10_CHECK_GAME_END: begin end
        endcase
    end
endmodule