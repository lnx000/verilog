/*外信号同步检测：
	通过两段式有限状态机实现
	在每个状态下都有一个计数器来计信号上升沿脉冲个数
	NO_SIGNAL:当信号脉冲个数达到阈值是说明信号来了，状态改变
	HAVE_SIGNAL:当信号脉冲在一段时间后小于阈值是说明信号消失，状态改变*/
module signal_detect #
(
	parameter TOTAL_TIME_CNT = 200,
	parameter THRESHOLD_VALUE = 26,
	parameter WIDTH = 32
)
(
	input wire clk,
	input wire rst,
	input wire signal,
	output wire signal_exitence
)

reg [1:0] current_state;
reg [1:0] next_state;
//外部信号边缘检测

reg signal_delay_1;
reg signal_delay_2;

wire signal_rise;

always@(posedge clk or posedge rst)
begin
	if(rst)
		begin
			signal_delay_1 <= 1'b0;
			signal_delay_1 <= 1'b1;
		end 
	else
		begin
			signal_delay_1 <= signal;
			signal_delay_2 <= signal_delay_1;
		end 
end

//检测信号上升沿
assign signal_rise = !signal_delay_2 && signal_delay_1;

//------------------------------------------------------------------------
//计数器1 用来第一个状态技术
reg [WIDTH-1:0] time_cnt1;

always@(posedge clk	or posedge rst)
begin
	if(rst)
		time_cnt1 <= 0;
	else if(time_cnt1 < TOTAL_TIME_CNT - 1 && current == 2'b01)
		time_cnt1 <= time_cnt1 + 1'b1;
	else
		time_cnt1 <= 0;
end 

//-----------------------------------------------------------------------------
//计数器2 用来第二个状态计数

reg [WIDTH-1:0] time_cnt2;

always@(posedge clk or posedge rst)
begin
	if(rst)
		time_cnt2 <= 0;
	else if(time_cnt2 < TOTAL_TIME_CNT - 1 && current_state == 2'b10)
		time_cnt2 <= time_cnt2 + 1'b1;
	else
		time_cnt2 <= 0;
end 

//----------------------------------------------------------------
//计算第一个状态下的signal——rise 的脉冲个数

reg [WIDTH-1:0] i;
always@(posedge clk or posedge rst)
begin
	if(rst)
		i <= 0;
	else if(time_cnt1 == 0)
		i <= 0;
	else if(signal_rise && current_state == 2'b01)//在固定时间内技术sig_rise出现的次数
		i <= i + 1'b1;
end 

//---------------------------------------------------------------------
//计算第二个转态signal_rise 的脉冲个数
reg [WIDTH-1:0] j;
always@(posedge clk or posedge rst)
begin
	if(rst)
		j <= 0;
	else if(time_cnt2 == 0)
		j <= 0;
	else if(signal_rise && current_state == 2'b10)
		j <= j + 1'b1;
end 

//--------------------------------------------------------------------------
//二段是有限状态机

localparam NO_SIGNAL = 2'b01;
localparam HAVE_SIGNAL = 2'b10;

//时序部分
always@(posedge clk or negedge rst)
begin
	if(rst)
		current_state <= NO_SIGNAL;
	else
		current_state <= next_state;
end 

//组合部分:描述转态的行为
//1.在NO_SIGNAL状态下，先是在一定时间段内，数脉冲的个数，当脉冲的个数大于了某个阈值时，立刻判断为，外同步信号存在。
//2.在HAVE_SIGNAL状态下，同样也是数脉冲的个数，当一段时间内，脉冲总数量小于某个阈值时，则判断为外同步信号丢失，状态跳转到NO_SIGNAL状态
always@( * )//在always块中组合逻辑是顺序执行的
begin
	next_state = NO_SIGNAL;//先对nextstate赋初始值
	case(current_state)
		NO_SIGNAL:
		begin
			if(i >= THRESHOLD_VALUE)
				next_state = HAVE_SIGNAL;
			else
				next_state = NO_SIGNAL;
		end
		
		HAVE_SIGNAL:
		begin
			if((time_cnt2 == TOTAL_TIME_CNT-1) && j < THRESHOLD_VALUE)//在时间边界时判断
				next_state <= NO_SIGNAL;//在时间域内脉冲个数不满足说明信号消失了
			else
				next_state = HAVE_SIGNAL;
		end
		
	endcase
end 

//-----------------------------------------------
//状态机输出信号驱动

reg signal_exitence_r;//同步输出

always@(posedge clk or posedge rst)
begin
	if(rst)
		begin
			signal_exitence_r <= 1'b0;
		end 
	else
		begin
			case(current_state)
				NO_SIGNAL:
				begin
					signal_exitence_r <= 1'b0;
				end 
				
				HAVE_SIGNAL:
				begin
					signal_exitence_r <= 1'b1;
				end  
			endcase
		end 
end 
				
				 