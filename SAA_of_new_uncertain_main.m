clc;clear;
tic
M=10;N=10;N_big=1000;
ship_type_fix=[2];
fuel_type_fix=[1:3];
start_Line=1;end_Line=37;
load('LineNetwork.mat');
load('BigDistanceMatrix.mat');
load('BigFuelPrice.mat');
load('CarbonTaxMatrix.mat');
load('CargoFareMatrix.mat');
load('LogitDemandNew.mat');

for num_M=1:M
    for ship_type=ship_type_fix    
        for fuel_type=fuel_type_fix   

            port_fuelconsume=port_fuelconsume_matrix(ship_type,fuel_type);
            fixedcost=fixedcost_matrix(ship_type,fuel_type);
            fuelCapacity=fuelCapacity_matrix(ship_type,fuel_type);
            containerCapacity=containerCapacity_matrix(ship_type,fuel_type);
            weightCapacity=weightCapacity_matrix(ship_type,fuel_type);
            parameter_fuel=parameter_fuel_matrix(ship_type,fuel_type);
            fix_carbontax_parameter=carbontax_matrix(1,fuel_type);

            for i=2*start_Line:2:2*end_Line

                Demand=[];Distance=[];Revenue=[];empty_cargocost=[];full_cargocost=[];FuelPrice=[];PORTDIST=[];port_code=[];carbontax_parameter=[];
                length=LineNetwork(1,i);
                for x=2:length+1
                    PORTDIST(1,x-1)=LineNetwork(x,i-1)/1.852;
                    port_code(1,x-1)=LineNetwork(x,i);
                    FuelPrice(1,x-1)=BigFuelPrice(LineNetwork(x,i),fuel_type);
                    carbontax_parameter(1,x-1)=fix_carbontax_parameter*CarbonTaxMatrix(LineNetwork(x,i),1);
                    for y=x+1:length+1
                        if BigDistanceMatrix(LineNetwork(x,i)+2,LineNetwork(y,i)+2)~=0
                            Distance(x-1,y-1)=BigDistanceMatrix(LineNetwork(x,i)+2,LineNetwork(y,i)+2);
                        elseif BigDistanceMatrix(LineNetwork(y,i)+2,LineNetwork(x,i)+2)~=0
                            Distance(x-1,y-1)=BigDistanceMatrix(LineNetwork(y,i)+2,LineNetwork(x,i)+2);
                        else
                            Distance(x-1,y-1)=0;
                        end
                        Revenue(x-1,y-1)=(0.2255*Distance(x-1,y-1)+481.76);
                        empty_cargocost(x-1,y-1)=CargoFareMatrix(LineNetwork(y,i),2);
                        full_cargocost(x-1,y-1)=CargoFareMatrix(LineNetwork(y,i),1);
                        if y==length+1
                            Distance(length,length)=0;
                            Revenue(length,length)=0;
                            empty_cargocost(length,length)=0;
                            full_cargocost(length,length)=0;
                        end
                    end
                end
                Demand=LogitDemand{1,i/2};
                TempFuelPrice=FuelPrice;
                TempDemand=Demand;
                TempRevenue=Revenue;
                Tempempty_cargocost=empty_cargocost;
                Tempfull_cargocost=full_cargocost;
                for num_N=1:N
                    [demand_parameter,fuel_parameter]=monte_carloA(fuel_type);
                    FuelPrice(1,(num_N-1)*size(PORTDIST,2)+1:num_N*size(PORTDIST,2))=fuel_parameter*TempFuelPrice;
                    Demand(1:LineNetwork(1,i),1+(num_N-1)*LineNetwork(1,i):num_N*LineNetwork(1,i))=demand_parameter*TempDemand;
                    Revenue(1:LineNetwork(1,i),1+(num_N-1)*LineNetwork(1,i):num_N*LineNetwork(1,i))=TempRevenue;
                    empty_cargocost(1:LineNetwork(1,i),1+(num_N-1)*LineNetwork(1,i):num_N*LineNetwork(1,i))=Tempempty_cargocost;
                    full_cargocost(1:LineNetwork(1,i),1+(num_N-1)*LineNetwork(1,i):num_N*LineNetwork(1,i))=Tempfull_cargocost;
                end

                [cmd,status,Carbon_tax,average_Speed,Total_Income,Total_cargocost,Total_empty_cargocost,Cargo_Matrix,Empty_Cargo_Matrix,result,Best_Objective,Speed,Fuel,Port_Decision,Fuel_Consume,Fuel_Remain,NumOfShip,Total_Fuel_Cost,Total_Fixed_Cost,Real_Speed]=up_subprogram(carbontax_parameter',port_waittime,port_fuelconsume,fixedcost,fuelCapacity,containerCapacity,weightCapacity,PORTDIST,FuelPrice,port_code,Demand,Revenue,empty_cargocost,full_cargocost,parameter_fuel,N);


                if Best_Objective~=0
                    AllLineResult{num_M,1}{ship_type,fuel_type}(1,i/2)=Best_Objective;
                    AllLineResult{num_M,1}{ship_type,fuel_type}(2,i/2)=Total_Income;
                    AllLineResult{num_M,1}{ship_type,fuel_type}(3,i/2)=Total_cargocost;
                    AllLineResult{num_M,1}{ship_type,fuel_type}(4,i/2)=Total_empty_cargocost;
                    AllLineResult{num_M,1}{ship_type,fuel_type}(5,i/2)=Total_Fuel_Cost;
                    AllLineResult{num_M,1}{ship_type,fuel_type}(6,i/2)=Carbon_tax;
                    AllLineResult{num_M,1}{ship_type,fuel_type}(7,i/2)=Total_Fixed_Cost;
                    AllLineResult{num_M,1}{ship_type,fuel_type}(8,i/2)=NumOfShip;
                    Big_Cargo_Matrix{num_M,1}{ship_type,fuel_type}{1,i/2}=  Cargo_Matrix;
                    Big_Empty_Cargo_Matrix{num_M,1}{ship_type,fuel_type}{1,i/2}= Empty_Cargo_Matrix;
                    Big_average_Speed{num_M,1}{ship_type,fuel_type}(1,1:N)=  average_Speed;
                    Big_All_Fuel{num_M,1}{ship_type,fuel_type}(1:N*length,i/2)= Fuel(1:N*length,1);
                    Big_Real_Speed{num_M,1}{ship_type,fuel_type}(1:N*length,i/2)= Real_Speed(1:N*length,1);
                    Big_Fuel_Remain{num_M,1}{ship_type,fuel_type}(1:N*length,i/2)= Fuel_Remain(1:N*length,1);
                    Big_Fuel_Consume{num_M,1}{ship_type,fuel_type}(1:N*length,i/2)=  Fuel_Consume(1:N*length,1);

                end
            end
        end
    end
end


save('GREEN_UP.mat')







N_big=1000;
for ship_type=ship_type_fix    
    for fuel_type=fuel_type_fix    

        port_fuelconsume=port_fuelconsume_matrix(ship_type,fuel_type);
        fixedcost=fixedcost_matrix(ship_type,fuel_type);
        fuelCapacity=fuelCapacity_matrix(ship_type,fuel_type);
        containerCapacity=containerCapacity_matrix(ship_type,fuel_type);
        weightCapacity=weightCapacity_matrix(ship_type,fuel_type);
        parameter_fuel=parameter_fuel_matrix(ship_type,fuel_type);
        fix_carbontax_parameter=carbontax_matrix(1,fuel_type);
        for i=2*start_Line:2:2*end_Line

            Temp_index=1;
            Temp_Revenue=-999999999;
            for num_M=1:M
                if AllLineResult{num_M,1}{ship_type,fuel_type}(1,i/2)>Temp_Revenue
                    Temp_index=num_M;
                    Temp_Revenue=AllLineResult{num_M,1}{ship_type,fuel_type}(1,i/2);
                end
            end
            Temp_NumOfShip=AllLineResult{Temp_index,1}{ship_type,fuel_type}(8,i/2);

            for cc=1:N_big

                Demand=[];Distance=[];Revenue=[];empty_cargocost=[];full_cargocost=[];FuelPrice=[];PORTDIST=[];port_code=[];carbontax_parameter=[];
                length=LineNetwork(1,i);
                for x=2:length+1
                    PORTDIST(1,x-1)=LineNetwork(x,i-1)/1.852;
                    port_code(1,x-1)=LineNetwork(x,i);
                    FuelPrice(1,x-1)=BigFuelPrice(LineNetwork(x,i),fuel_type);
                    carbontax_parameter(1,x-1)=fix_carbontax_parameter*CarbonTaxMatrix(LineNetwork(x,i),1);
                    for y=x+1:length+1
                        if BigDistanceMatrix(LineNetwork(x,i)+2,LineNetwork(y,i)+2)~=0
                            Distance(x-1,y-1)=BigDistanceMatrix(LineNetwork(x,i)+2,LineNetwork(y,i)+2);
                        elseif BigDistanceMatrix(LineNetwork(y,i)+2,LineNetwork(x,i)+2)~=0
                            Distance(x-1,y-1)=BigDistanceMatrix(LineNetwork(y,i)+2,LineNetwork(x,i)+2);
                        else
                            Distance(x-1,y-1)=0;
                        end
                        Revenue(x-1,y-1)=(0.2255*Distance(x-1,y-1)+481.76);
                        empty_cargocost(x-1,y-1)=CargoFareMatrix(LineNetwork(y,i),2);
                        full_cargocost(x-1,y-1)=CargoFareMatrix(LineNetwork(y,i),1);
                        if y==length+1
                            Distance(length,length)=0;
                            Revenue(length,length)=0;
                            empty_cargocost(length,length)=0;
                            full_cargocost(length,length)=0;
                        end
                    end
                end
                Demand=LogitDemand{1,i/2};
                TempFuelPrice=FuelPrice;
                TempDemand=Demand;
                for num_N=1:1
                    [demand_parameter,fuel_parameter]=monte_carloA(fuel_type);
                    FuelPrice(1,(num_N-1)*size(PORTDIST,2)+1:num_N*size(PORTDIST,2))=fuel_parameter*TempFuelPrice;
                    Demand(1:LineNetwork(1,i),1+(num_N-1)*LineNetwork(1,i):num_N*LineNetwork(1,i))=demand_parameter*TempDemand;
                end

                [cmd,status,Carbon_tax,average_Speed,Total_Income,Total_cargocost,Total_empty_cargocost,Cargo_Matrix,Empty_Cargo_Matrix,result,Best_Objective,Speed,Fuel,Port_Decision,Fuel_Consume,Fuel_Remain,NumOfShip,Total_Fuel_Cost,Total_Fixed_Cost,Real_Speed]=low_subprogram(carbontax_parameter,port_waittime,port_fuelconsume,fixedcost,fuelCapacity,containerCapacity,weightCapacity,PORTDIST,FuelPrice,port_code,Demand,Revenue,empty_cargocost,full_cargocost,parameter_fuel,Temp_NumOfShip);

                num_M=1;
                AllLineResult_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(1,cc)=Best_Objective;
                AllLineResult_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(2,cc)=Total_Income;
                AllLineResult_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(3,cc)=Total_cargocost;
                AllLineResult_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(4,cc)=Total_empty_cargocost;
                AllLineResult_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(5,cc)=Total_Fuel_Cost;
                AllLineResult_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(6,cc)=Carbon_tax;
                AllLineResult_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(7,cc)=Total_Fixed_Cost;
                AllLineResult_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(8,cc)=NumOfShip;
                AllLineResult_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(9,cc)=average_Speed;
                Big_Cargo_Matrix_UP{num_M,1}{ship_type,fuel_type}{1,i/2}{1,cc}=  Cargo_Matrix;
                Big_Empty_Cargo_Matrix_UP{num_M,1}{ship_type,fuel_type}{1,i/2}{1,cc}= Empty_Cargo_Matrix;
                Big_All_Fuel_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(1:length,cc)= Fuel(1:length,1);
                Big_Real_Speed_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(1:length,cc)= Real_Speed(1:length,1);
                Big_Fuel_Remain_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(1:length,cc)= Fuel_Remain(1:length,1);
                Big_Fuel_Consume_UP{num_M,1}{ship_type,fuel_type}{1,i/2}(1:length,cc)=  Fuel_Consume(1:length,1);
            end
            save('GREEN_LOW.mat')
        end
    end
end



toc






