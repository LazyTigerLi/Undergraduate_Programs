`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB（Embeded System Lab�?
// Engineer: Haojun Xia & Xuan Wang
// Create Date: 2019/02/22
// Design Name: RISCV-Pipline CPU
// Module Name: HarzardUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Deal with harzards in pipline
//////////////////////////////////////////////////////////////////////////////////
module HarzardUnit(
    input wire CpuRst, ICacheMiss, DCacheMiss, 
    input wire BranchE, JalrE, JalD, 
    input wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
    input wire [1:0] RegReadE,
    input wire [2:0] RegWriteM, RegWriteW,
    input wire MemToRegE,
    output reg StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW,
    output reg [1:0] Forward1E, Forward2E
    );
    //Stall and Flush signals generate
    always @ (*)
    begin
        if(CpuRst)begin FlushF <= 1'b1; FlushD <= 1'b1; FlushE <= 1'b1; FlushM <= 1'b1; FlushW <= 1'b1;
                    StallF <= 1'b0; StallD <= 1'b0; StallE <= 1'b0; StallM <= 1'b0; StallW <= 1'b0; end
        else
        begin
            if((RdE == Rs1D || RdE == Rs2D) && MemToRegE)       //Load + use
                begin FlushF <= 1'b0; FlushD <= 1'b0; FlushE <= 1'b0; FlushM <= 1'b0; FlushW <= 1'b0; 
                    StallF <= 1'b1; StallD <= 1'b1; StallE <= 1'b0; StallM <= 1'b0; StallW <= 1'b0; end
            else if(BranchE | JalrE)
                begin FlushF <= 1'b0; FlushD <= 1'b1; FlushE <= 1'b1; FlushM <= 1'b0; FlushW <= 1'b0; 
                    StallF <= 1'b0; StallD <= 1'b0; StallE <= 1'b0; StallM <= 1'b0; StallW <= 1'b0; end
            //���ﷸ��һ������һ��ʼ��Ϊ��IF��ID�μ�Ĵ�����Ҫ��գ��������֣����IF�ε�clear�ź�Ϊ1���⽫�����¸����ڿ�ʼʱ���µ�PC�޷�д��
            else if(JalD)
                begin FlushF <= 1'b0; FlushD <= 1'b1; FlushE <= 1'b0; FlushM <= 1'b0; FlushW <= 1'b0; 
                    StallF <= 1'b0; StallD <= 1'b0; StallE <= 1'b0; StallM <= 1'b0; StallW <= 1'b0; end 
  
            else begin FlushF <= 1'b0; FlushD <= 1'b0; FlushE <= 1'b0; FlushM <= 1'b0; FlushW <= 1'b0; 
                    StallF <= 1'b0; StallD <= 1'b0; StallE <= 1'b0; StallM <= 1'b0; StallW <= 1'b0; end
        end
    end
    
    //Forward Register Source 1
    always @ (*)
    begin
        if(Rs1E == RdM && Rs1E != 5'd0 && RegReadE[1] == 1'b1 && RegWriteM != 3'd0)
            Forward1E <= 2'b10;                 //EX/MEM.rd = ID/EX.rs1, ����rs1���õ�������rd����δ��ɵ�д��
        else if(Rs1E == RdW && Rs1E != 5'd0 && RegReadE[1] == 1'b1 && RegWriteW != 3'd0)
            Forward1E <= 2'b01;                 //MEM/WB.rd = ID/EX.rs1, ����rs1���õ�������rd����δ��ɵ�д��
        else Forward1E <= 2'b00;
        
        if(Rs2E == RdM && Rs2E != 5'd0 && RegReadE[0] == 1'b1 && RegWriteM != 3'd0)
            Forward2E <= 2'b10;                 //EX/MEM.rd = ID/EX.rs2, ����rs2���õ�������rd����δ��ɵ�д��
        else if(Rs2E == RdW && Rs2E != 5'd0 && RegReadE[0] == 1'b1 && RegWriteW != 3'd0)
            Forward2E <= 2'b01;                 //MEM/WB.rd = ID/EX.rs2, ����rs2���õ�������rd����δ��ɵ�д��                
        else Forward2E <= 2'b00;
    end
    //Forward Register Source 2

endmodule

//功能说明
    //HarzardUnit用来处理流水线冲突，通过插入气泡，forward以及冲刷流水段解决数据相关和控制相关，组合�?�辑电路
    //可以�?后实现�?�前期测试CPU正确性时，可以在每两条指令间插入四条空指令，然后直接把本模块输出定为，不forward，不stall，不flush 
//输入
    //CpuRst                                    外部信号，用来初始化CPU，当CpuRst==1时CPU全局复位清零（所有段寄存器flush），Cpu_Rst==0时cpu�?始执行指�?
    //ICacheMiss, DCacheMiss                    为后续实验预留信号，暂时可以无视，用来处理cache miss
    //BranchE, JalrE, JalD                      用来处理控制相关
    //Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW     用来处理数据相关，分别表示源寄存�?1号码，源寄存�?2号码，目标寄存器号码
    //RegReadE RegReadD[1]==1                   表示A1对应的寄存器值被使用到了，RegReadD[0]==1表示A2对应的寄存器值被使用到了，用于forward的处�?
    //RegWriteM, RegWriteW                      用来处理数据相关，RegWrite!=3'b0说明对目标寄存器有写入操�?
    //MemToRegE                                 表示Ex段当前指�? 从Data Memory中加载数据到寄存器中
//输出
    //StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW    控制五个段寄存器进行stall（维持状态不变）和flush（清零）
    //Forward1E, Forward2E                                                              控制forward
//实验要求  
    //实现HarzardUnit模块   