/*���ź�ͬ����⣺
	ͨ������ʽ����״̬��ʵ��
	��ÿ��״̬�¶���һ�������������ź��������������
	NO_SIGNAL:���ź���������ﵽ��ֵ��˵���ź����ˣ�״̬�ı�
	HAVE_SIGNAL:���ź�������һ��ʱ���С����ֵ��˵���ź���ʧ��״̬�ı�*/
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
//�ⲿ�źű�Ե���

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

//����ź�������
assign signal_rise = !signal_delay_2 && signal_delay_1;

//------------------------------------------------------------------------
//������1 ������һ��״̬����
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
//������2 �����ڶ���״̬����

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
//�����һ��״̬�µ�signal����rise ���������

reg [WIDTH-1:0] i;
always@(posedge clk or posedge rst)
begin
	if(rst)
		i <= 0;
	else if(time_cnt1 == 0)
		i <= 0;
	else if(signal_rise && current_state == 2'b01)//�ڹ̶�ʱ���ڼ���sig_rise���ֵĴ���
		i <= i + 1'b1;
end 

//---------------------------------------------------------------------
//����ڶ���ת̬signal_rise ���������
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
//����������״̬��

localparam NO_SIGNAL = 2'b01;
localparam HAVE_SIGNAL = 2'b10;

//ʱ�򲿷�
always@(posedge clk or negedge rst)
begin
	if(rst)
		current_state <= NO_SIGNAL;
	else
		current_state <= next_state;
end 

//��ϲ���:����ת̬����Ϊ
//1.��NO_SIGNAL״̬�£�������һ��ʱ����ڣ�������ĸ�����������ĸ���������ĳ����ֵʱ�������ж�Ϊ����ͬ���źŴ��ڡ�
//2.��HAVE_SIGNAL״̬�£�ͬ��Ҳ��������ĸ�������һ��ʱ���ڣ�����������С��ĳ����ֵʱ�����ж�Ϊ��ͬ���źŶ�ʧ��״̬��ת��NO_SIGNAL״̬
always@( * )//��always��������߼���˳��ִ�е�
begin
	next_state = NO_SIGNAL;//�ȶ�nextstate����ʼֵ
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
			if((time_cnt2 == TOTAL_TIME_CNT-1) && j < THRESHOLD_VALUE)//��ʱ��߽�ʱ�ж�
				next_state <= NO_SIGNAL;//��ʱ�������������������˵���ź���ʧ��
			else
				next_state = HAVE_SIGNAL;
		end
		
	endcase
end 

//-----------------------------------------------
//״̬������ź�����

reg signal_exitence_r;//ͬ�����

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
				
				 