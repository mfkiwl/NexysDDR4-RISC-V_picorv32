// Belinda Brown Ramírez
// Brandon Esquivel Molina
// December, 2020
// timna.brown@ucr.ac.cr
// brandon.esquivel@ucr.ac.cr
//github: @brown9804, @brandonEsquivel

`ifndef PRS_GAME
`define PRS_GAME


module prs_game #(
parameter LEDSEGMENTS = 7) (
  //INPUTS
  input wire clk,
  input wire resetn,
  input wire PS2Clk,
  input wire PS2Data,
  // OUTPUTS
  output reg [LEDSEGMENTS: 0] catode,
  output reg [LEDSEGMENTS: 0] anode
);

// LOGIC // 2^n = possible values -> need 9 - 4 bits
// select   text
// 0        Start       // 0000
// 1        Select:     // 0001
// 2        Paper       // 0010
// 3        Scissors    // 0011
// 4        Rock        // 0100
// 5        Rival:      // 0101
// 6        You won     // 0110
// 7        You lost    // 0111
// 8        Tie         // 1000

localparam Start    = 4'b0000; // # letter 5
localparam Select   = 4'b0001; // # letter 6
localparam Paper    = 4'b0010; // # letter 5
localparam Scissors = 4'b0011; // # letter 7
localparam Rock     = 4'b0100; // # letter 4
localparam Rival    = 4'b0101; // # letter 5
localparam YouWON   = 4'b0110; // # letter 6
localparam YouLOST  = 4'b0111; // # letter 7
localparam Tie      = 4'b1000; // # letter 3

wire [7:0] cdt; // catode_display_number_going_to_be_traduced
wire [7:0] adt; // anode_display_number_going_to_be_traduced
reg [63:0] mem; // complete command

// -----------------------------------------------------------------------------------------------
///  7 SEGMENTS  DISPLAY 
/// Using  ->
// DP g f e d c b a 
// -----------------------------------------------------------------------------------------------
///                         0        0         0       S        T         A        r       T
// START - CATODE      = 11111111 11111111 11111111 11010010 10000111 10001000 10101111 10000111
//                          0        0         S        E        L        E        c       T
// SELECT - CATODE     = 11111111 11111111 11010010 10000110 11000111 10000110 10100111 10000111
//                          0        0         0        P       A        P        E        r
// PAPER - CATODE      = 11111111 11111111 11111111 10001100 10001000 10001100 10000110 10101111
//                          S         C        i       S        S        O         r       S
// SCISSORS - CATODE   = 11010010 10100111 11101110 11010010 11010010 10100011 10101111 11010010
//                          0        0         0       0         r        o       c        k
// ROCK - CATODE       = 11111111 11111111 11111111 11111111 10101111 10100011 10100111 10001010
//                         0         0         0        r      i         V         A       L
// RIVAL - CATODE      = 11111111 11111111 11111111 10101111 11101110 11010101 10001000 11000111
//                         0         0       Y         o       u         w         o       n
// YOUWON - CATODE     = 11111111 11111111 10010001 10100011 11100011 10010101 10100011 10101011
//                         0          Y        o        u        L        o        S       E
// YOULOST - CATODE    = 11111111 10010001 10100011 11100011 11000111 10100011 11010010 10000111
//                         0         0         0       0        0        T        i        E
// TIE - CATODE        = 11111111 11111111 11111111 11111111 11111111 10000111 11101110 10000110
x7_segment_hex x7_segment_hex_inst(
.displayed_number   (mem),
.clk         (clk),
.resetn     (resetn),
.seg        (   cdt ),
.Anode_on   (   adt )
);
// -----------------------------------------------------------------------------------------------
// PS2
// -----------------------------------------------------------------------------------------------
reg CLK50MHZ=0;
wire [7:0] selector;
reg [7:0] userchoice;
reg [7:0] rivaloption;
reg [3:0] comparation;
/// CLK for ps2
always @(posedge(clk))begin
    CLK50MHZ <= ~CLK50MHZ;
end
// ---- module
PS2_Controller Mouse (
.CLOCK_50    (CLK50MHZ),
.PS2_CLK     (PS2_CLK),
.PS2_DAT     (PS2_DATA),
.received_data (selector[7:0])
);


localparam READ_BYTE1 = 3'b001;
localparam READ_BYTE2 = 3'b010;
localparam READ_BYTE3 = 3'b100;

reg right_click;
reg [2:0] state;
reg wheel;
reg [7:0] X_axis;
reg [7:0] Y_axis;
reg next_rival, next_compare;
reg userOption, next_start, next_select_print,next_choice;


     
 always@(posedge clk) begin
        if (resetn) begin
            right_click <=0;
            state       <=0;
            wheel       <=0;
            X_axis      <=0;
            Y_axis      <=0;
            next_rival  <=0;
            next_compare<=0;
            next_start  <=1;
            next_choice <=0;
        end else begin
        // START: 
// -> Display START message 
// anode <= 8'b11100000;

     if(next_start) begin
        mem <= 64'b1111111111111111111111111101001010000111100010001010111110000111; // 0.0.0.S.T.A.R.T
        next_select_print   <= 1;
        next_start          <= 0;
      end else begin
 // SELECT
//-> Display SELECT message 
   // anode <= 8'b10000000;
     if(next_select_print) begin
        #(35000);
        next_choice <= 1;
        mem <= 64'b1111111111111111110100101000011011000111100001101010011110000111; // 0.0.S.E.L.E.C.T
        next_select_print  <=0;
      end else begin
      
          case (state)    
            READ_BYTE1: begin
                    right_click  <= selector[1];
                    wheel       <= selector[3];
                    state <= READ_BYTE2;
                end
            READ_BYTE2: begin
                X_axis <= selector; 
                state <= READ_BYTE3;
                end
            READ_BYTE3: begin
                Y_axis <= selector;
                state <= READ_BYTE1;
                end
             endcase
             
          if(next_choice) begin
// USER OPTIONS DISPLAY // • Paper // • Rock  // • Scissors
        case(userchoice)
            Paper: begin
                mem <= 64'b1111111111111111111111111000110010001000100011001000011010101111; // 0.0.0.P.A.P.E.R
                end // end case 2
            Scissors: begin
                mem <= 64'b1101001010100111111011101101001011010010101000111010111111010010; // S.C.I.S.S.O.R.S
                end // end case 3
            Rock: begin
                mem <= 64'b1111111111111111111111111111111110101111101000111010011110001010; // 0.0.0.0.0.R.O.C.K
                end   // end case 4
            default: begin
                mem <= 64'b1111111111111111111111111111111111111111111111111111111111111111; // . . . . . .
            end
        endcase // end user choice display
       end // end if userchoice
//---------------------------------
            else begin
             if (next_rival) begin
// RIVAL:
// -> Display RIVAL
    //anode <= 8'b11100000;
        mem <= 64'b1111111111111111111111111010111111101110110101011000100011000111; // 0.0.0.R.I.V.A.L

// INSERTING DELAY:
// remembering `timescale 1 ns / 1 ps
// mm um nm pm
       #(35000);
//---------------------------------
// CHOOSE RIVAL OPTION
// Paper    = 4'b010; - 2
// Scissors = 4'b011; - 3
// Rock     = 4'0100; - 4
// $urandom_range(maxVal,minVal)
// Randomize number between 2 and 4
//// reference https://stackoverflow.com/questions/41166023/systemverilog-how-can-i-use-urandom-random-with-range
        rivaloption <= $urandom_range(4,2);
//---------------------------------
// DISPLAY RANDOM RIVAL OPTION
        case(rivaloption)
            Paper: begin
            // anode <= 8'b11100000;
                mem <= 64'b1111111111111111111111111000110010001000100011001000011010101111; // 0.0.0.P.A.P.E.R
            end // end case 2
            Scissors: begin 
            // anode <= 8'b00000000;
                mem <= 64'b1101001010100111111011101101001011010010101000111010111111010010; // S.C.I.S.S.O.R.S
                end // end case 3
            Rock: begin 
            // anode <= 8'b11110000;
                mem <= 64'b1111111111111111111111111111111110101111101000111010011110001010; // 0.0.0.0.0.R.O.C.K
                end   // end case 4
            default: begin 
                mem <= 64'b1111111111111111111111111111111111111111111111111111111111111111; // . . . . . .
            // anode <= 8'b00000000;
            end
        endcase // end rival option display

    end // end if rival
    next_compare <= 1;
            
            end 
            end
        end
    end
end

always @(selector) begin
    if ((userchoice >= 4) || (rivaloption >= 4)) begin
        userchoice <= 2;
        rivaloption <= 2;
    end
    else begin
        userchoice <= userchoice + 1;
        rivaloption <= rivaloption + 1;
    end

    if (right_click) begin
        userOption <= userchoice;
        next_rival <= 1;
    end
end



always@(posedge next_compare) begin
// INSERTING DELAY:
// remembering `timescale 1 ns / 1 ps
// mm um nm pm
       #(35000);
//---------------------------------

//---------------------------------
// LOGIC FOR COMPARING  
// POSSIBLE COMBINATIONS 
// USER      -    RIVAL 
// scrissors -    paper ----> WON 
// scrissors -    rock ----> LOST 
// paper -    scrissors ----> LOST 
// paper -    rock ----> WON 
// rock -    scrissors ----> WON 
// rock -    paper ----> LOST 
// CHOOSE RIVAL OPTION
        if (userOption == rivaloption) begin 
            comparation <= Tie;
        end 
        // USER CHOICE SCISSORS 
        else if ((userOption == Scissors) && (rivaloption == Paper)) begin 
            comparation <= YouWON;
        end 
        else if ((userOption == Scissors) && (rivaloption == Rock)) begin 
            comparation <= YouLOST;
        end 
        // USER CHOICE PAPER 
        else if ((userOption == Paper) && (rivaloption == Scissors)) begin 
            comparation <= YouLOST;
        end 
        else if ((userOption == Paper) && (rivaloption == Rock)) begin 
            comparation <= YouWON;
        end 
        // USER CHOICE ROCK 
        else if ((userOption == Rock) && (rivaloption == Scissors)) begin 
            comparation <= YouWON;
        end 
        else if ((userOption == Rock) && (rivaloption == Paper)) begin 
            comparation <= YouLOST;
        end 
        // DEFAULT 
        else begin 
            comparation <= Tie;
        end 
//---------------------------------
// COMPARE RANDOM CHOICE WITH USER CHOICE 
        case(comparation)
            YouWON: begin 
                //anode <= 8'b11000000;
                mem <= 64'b1111111111111111100100011010001111100011100101011010001110101011; // 0.0.Y.O.U.W.O.N
                end   // end case 6
            YouLOST: begin 
                //anode <= 8'b10000000;
                mem <= 64'b1111111110010001101000111110001111000111101000111101001010000111; // 0.Y.O.U.L.O.S.T
                end  // end case 7
            Tie: begin 
                //anode <= 8'b11111000;
                mem <= 64'b1111111111111111111111111111111111111111100001111110111010000110; //0.0.0.0.0.T.I.E
                end    // end case 8
            default: begin 
                mem <= 64'b1111111111111111111111111111111111111111111111111111111111111111; // . . . . . .
                //anode <= 8'b111111111;
            end
        endcase
    end // end always next compare





always@(*)begin
 catode = cdt;
 anode = adt;
end

endmodule 


// Local Variables:
// verilog-library-directories:("."):
// End:
`endif
