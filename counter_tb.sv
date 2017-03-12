`timescale 1ns/1ps

module counter_tb;

// define system frequency in MHz
`define FREQ 50
`define PER 1000/`FREQ

// define DUT parameters
`define CNT_WIDTH 3

// testbench variables
reg tb_clk;
reg tb_reset_;
reg tb_load_;
reg tb_cnt_dir;
reg tb_cnt_en_;
reg [1:0] tb_cnt_type;
reg [`CNT_WIDTH-1:0] tb_cnt_in;

reg [`CNT_WIDTH-1:0] tb_exp_cnt;

wire [`CNT_WIDTH-1:0] tb_out_cnt;

// instantiate DUT
counter_top 
	#(
		.COUNT_WIDTH(`CNT_WIDTH)
	)
dut
	(
		.clk(tb_clk),
		.reset_(tb_reset_),
		.count_dir(tb_cnt_dir),
		.count_enable_(tb_cnt_en_),
		.count_type(tb_cnt_type),
		.load_(tb_load_),
		.load_val(tb_cnt_in),
		.count(tb_out_cnt)
	);

// generate
initial begin
	tb_clk = 1'b0;
	forever begin
		#(`PER/2) tb_clk = !tb_clk;
	end
end

// initialize simulation
initial begin
	// generate POR
	tb_reset_ = 1'b0;
	repeat (20) @(posedge tb_clk);
	tb_reset_ = 1'b1;
end

initial begin
	tb_load_ = 1'b1;
	tb_cnt_dir = 1'b1;
	tb_cnt_en_ = 1'b1;
	tb_cnt_type = 2'd0;
	tb_cnt_in = {`CNT_WIDTH{1'b0}};

	// call test
	test_task();
end

// finish
final begin
	$display("[%0d] Simulation finished\n", $realtime);
end

// verifier - checker
always @(posedge tb_clk) begin
	#0.001;
	if (tb_exp_cnt === tb_out_cnt) begin
		$display("[%0d] SUCCESS! Value is as expected - %0b", $realtime, tb_exp_cnt);
	end
	else begin
		$display("[%0d] FAIL! Value is %0b, expected %0b", $realtime, tb_out_cnt, tb_exp_cnt);
	end
end

// verifier - explected values
always @(posedge tb_clk) begin
	if (!tb_reset_) begin
		$display("[%0d] In reset!\n", $realtime);
		tb_exp_cnt = 'h0;
	end
	else begin
		if (!tb_load_) begin
			tb_exp_cnt = tb_cnt_in;
		end
		else begin
			if (!tb_cnt_en_) begin
				if (tb_cnt_type == 2'b00) begin
					if (tb_cnt_dir) begin
						tb_exp_cnt++;
					end
					else begin
						tb_exp_cnt--;
					end
				end
				else if (tb_cnt_type == 2'b01) begin
					gray2bin(tb_exp_cnt,tb_exp_cnt);
					if (tb_cnt_dir) begin
						tb_exp_cnt++;
					end
					else begin
						tb_exp_cnt--;
					end
					bin2gray(tb_exp_cnt,tb_exp_cnt);
				end
				else if (tb_cnt_type == 2'b01) begin
					if (tb_cnt_dir) begin
						tb_exp_cnt = {tb_exp_cnt[0], tb_exp_cnt[`CNT_WIDTH-1:1]};
					end
					else begin
						tb_exp_cnt = {tb_exp_cnt[`CNT_WIDTH-2:0],tb_exp_cnt[`CNT_WIDTH-1]};
					end
				end
				else begin // tb_cnt_type == 2'b10
					if (tb_cnt_dir) begin
						tb_exp_cnt = {~tb_exp_cnt[0], tb_exp_cnt[`CNT_WIDTH-1:1]};
					end
					else begin
						tb_exp_cnt = {tb_exp_cnt[`CNT_WIDTH-2:0],~tb_exp_cnt[`CNT_WIDTH-1]};
					end
				end
			end
		end
	end
end

task test_task;
	//wait reset compleete
	wait (tb_reset_ == 1'b1);
	// wait to be sure that reset is done
	repeat (1) @(posedge tb_clk);
	// set inputs
	tb_cnt_dir = 1'b1;
	tb_cnt_in = 'b101;
	tb_cnt_type = 2'b01;
	tb_load_ = 1'b1;
	tb_cnt_en_ = 1'b1;
	repeat (1) @(posedge tb_clk);
	tb_load_ = 1'b0;
	repeat (1) @(posedge tb_clk);
	tb_load_ = 1'b1;
	tb_cnt_en_ = 1'b0;
	repeat (16) @(posedge tb_clk);
	$finish;
endtask

task bin2gray;
	input [`CNT_WIDTH-1:0] bin;
	output [`CNT_WIDTH-1:0] gray;
	
	integer i;

	for (i=0;i<=`CNT_WIDTH-2;i++) begin
		gray[i] = bin[i] ^ bin[i+1];
	end
	gray[`CNT_WIDTH-1] = bin[`CNT_WIDTH-1];
endtask

task gray2bin;
	input [`CNT_WIDTH-1:0] gray;
	output [`CNT_WIDTH-1:0] bin;
	
	integer i;
	
	bin[`CNT_WIDTH-1] = gray[`CNT_WIDTH-1];
	for (i=`CNT_WIDTH-2;i>=0;i--) begin
		bin[i] = gray[i] ^ bin[i+1];
	end
endtask

endmodule
