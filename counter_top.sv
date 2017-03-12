//cineva a uita sa puna un header

module counter_top
	(
		clk,
		reset_,
		count_dir,
		count_enable_,
		count_type,
		load_,
		load_val,
		count
	);

parameter COUNT_WIDTH = 4;

// count_type values:
// - 2'd0 = binary (default)
// - 2'd1 = gray
// - 2'd2 = ring
// - 2'd3 = johnson

// count_dir values:
// - 1'b0 = down
// - 1'b1 = up (default)
input clk;
input reset_;
input count_dir;
input count_enable_;
input [1:0] count_type;
input load_;
input [COUNT_WIDTH-1:0] load_val;

output reg [COUNT_WIDTH-1:0] count;

reg [COUNT_WIDTH-1:0] count_d;
reg [COUNT_WIDTH-1:0] count_bin;
reg [1:0] count_type_ff, count_type_d;

// combinational process
always @(*) begin
	count_d = count;
	count_type_d = count_type_ff;
	if (!load_) begin
		count_d = load_val;
		count_type_d = count_type;
	end
	else begin
		if (!count_enable_) begin
			case (count_type_ff)
				2'd0: //binary
					begin
						if (count_dir) begin
							count_d = count + 'h1;
						end
						else begin
							count_d = count - 'h1;
						end
					end
				2'd1: //gray
					begin
						gray2bin(count,count_bin);
						if (count_dir) begin
							count_bin = count_bin + 'h1;
						end
						else begin
							count_bin = count_bin - 'h1;
						end
						bin2gray(count_bin,count_d);
					end
				2'd2: //ring
					begin
						if (count_dir) begin
							count_d = {count[0], count[COUNT_WIDTH-1:1]};
						end
						else begin
							count_d = {count[COUNT_WIDTH-2:0],count[COUNT_WIDTH-1]};
						end
					end
				2'd3: //johnson
					begin
						if (count_dir) begin
							count_d = {~count[0], count[COUNT_WIDTH-1:1]};
						end
						else begin
							count_d = {count[COUNT_WIDTH-2:0],~count[COUNT_WIDTH-1]};
						end
					end	
				default:
					$display("Can't get here!\n");
			endcase
		end
	end
end

// flip-flops
always @(posedge clk) begin
	if (!reset_) begin
		count <= 'h0;
		count_type_ff <= 2'd0; //reset to binary
	end
	else begin
		count <= count_d;
		count_type_ff <= count_type_d;
	end
end

task bin2gray;
	input [COUNT_WIDTH-1:0] bin;
	output [COUNT_WIDTH-1:0] gray;
	
	integer i;

	for (i=0;i<=COUNT_WIDTH-2;i++) begin
		gray[i] = bin[i] ^ bin[i+1];
	end
	gray[COUNT_WIDTH-1] = bin[COUNT_WIDTH-1];
endtask

task gray2bin;
	input [COUNT_WIDTH-1:0] gray;
	output [COUNT_WIDTH-1:0] bin;
	
	integer i;
	
	bin[COUNT_WIDTH-1] = gray[COUNT_WIDTH-1];
	for (i=COUNT_WIDTH-2;i>=0;i--) begin
		bin[i] = gray[i] ^ bin[i+1];
	end
endtask

endmodule
