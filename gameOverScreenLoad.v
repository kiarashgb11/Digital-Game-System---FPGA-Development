module gameOverScreenLoad(iColour,iClock,oX,oY,oColour,oPlot,oDone, gameOver);
   parameter X_SCREEN_PIXELS = 10'd320;
   parameter Y_SCREEN_PIXELS = 9'd240;
																																																																																													
   input wire gameOver;
   input wire iColour;
   input wire 	    iClock;
   output reg [10:0] oX;         // VGA pixel coordinates
   output reg [9:0] oY;

   output reg [2:0] oColour;     // VGA pixel colour (0-7)
   output reg 	     oPlot;       // Pixel draw enable
   output reg       oDone;       // goes high when finished drawing frame
	
	wire [11:0] colourRead;
	
	reg [10:0] x_count;
	reg [9:0] y_count;
	
	parameter height = 240;
	parameter width = 320;
	
	always @(posedge iClock) begin
		  if (gameOver == 1) begin
			  if(x_count >= 320 && y_count >= 240) begin 
					x_count <= 0;
					y_count <= 0;

				end
				if (x_count == 0 && y_count == 0) begin
					oDone <= 0;
				end
			   begin	 
						 oX <= x_count;
						 oY <= y_count;
						 
						 if (x_count < 320)
							  begin
									x_count <= x_count + 1;
							  end
						 else if (y_count < 240)
							  begin
									x_count <= 0;
									y_count <= y_count + 1;
									if (y_count == height)
										 oDone <= 1'b1;
							  end
							  
						 
			  end
		 end 
    end
	 
	 gameOverRam loadRAM(.address(320*oY + oX), .clock(CLOCK_50), .data(4'b0), .wren(1'b0), .q(colourRead[11:0]));
	 
	 
	 always @(posedge iClock) begin
		oColour <= colourRead;
	 end
endmodule // part2


