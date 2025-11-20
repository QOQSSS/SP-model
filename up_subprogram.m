function [cmd,status,Carbon_tax,average_Speed,Total_Income,Total_cargocost,Total_empty_cargocost,Cargo_Matrix,Empty_Cargo_Matrix,result,Best_Objective,Speed,Fuel,Port_Decision,Fuel_Consume,Fuel_Remain,NumOfShip,Total_Fuel_Cost,Total_Fixed_Cost,Real_Speed]=up_subprogram(carbontax_parameter,port_waittime,port_fuelconsume,fixedcost,fuelCapacity,containerCapacity,weightCapacity,PORTDIST,FuelPrice,port_code,Demand,Revenue,empty_cargocost,full_cargocost,parameter_fuel,N)


params.earliest_arrival = [];
params.latest_arrival = [];                                
params.coefficient1 = 20 ;                                      
params.coefficient2 = 2.3;                                   
params.min_port_time = port_waittime;    
params.W_3 = port_fuelconsume;              
params.fixed_cost = fixedcost;   
params.W = fuelCapacity;              
params.capacity = containerCapacity;  
params.total_weight = weightCapacity;  
params.n = length(PORTDIST);                       
params.m = length(PORTDIST);
params.N =N;
params.distance = PORTDIST;                       
params.fuel_cost = FuelPrice;                         
params.ports = port_code;                             
params.DEMAND = Demand;                              
params.REVENUE = Revenue;                          
params.empty_cargo_cost = empty_cargocost;      
params.full_cargo_cost = full_cargocost;               
params.parameterfuel = parameter_fuel;               
params.carbontax_parameter=carbontax_parameter; 
paramsJson = jsonencode(params);                     



tempFile = [tempname, '.json'];

fid = fopen(tempFile, 'w');
if fid == -1
    error('Cannot open file for writing: %s', tempFile);
end
fprintf(fid, '%s', paramsJson);
fclose(fid);


python_path = 'D:\anaconda\python.exe';
script_path ='C:\Users\Hasee\Desktop\new_function_up.py';


cmd = [python_path, ' ', script_path, ' ', tempFile];
[status, result] = system(cmd);



pattern = '\{(?:[^{}]|(?R))*\}';
matches = regexp(result, pattern, 'match');
if ~isempty(matches)
    jsonStr = matches{end};
    disp('Last:');
    disp(jsonStr);
    data = jsondecode(jsonStr);
    
    % 检查是否有错误信息
    if isfield(data, 'error')
        disp(['error: ', data.error]);
        Best_Objective=0;
        Speed=0;
        Fuel=0;
        Port_Decision=0;
        Fuel_Consume=0;
        Fuel_Remain=0;
        Travel_Time=0;
        Ship_Arrival_Time=0;
        NumOfShip=0;
        Total_Fuel_Cost=0;
        Total_Fixed_Cost=0;
        Real_Speed=0;
        Cargo_Matrix=0;
        Empty_Cargo_Matrix=0;
        Total_Income=0;
        Total_cargocost=0;
        Total_empty_cargocost=0;
    else

        Speed = data.Speed;
        Fuel = data.Fuel;
        Port_Decision = data.Port_Decision;
        Fuel_Consume = data.Fuel_Consume;
        Fuel_Remain = data.Fuel_Remain;
        NumOfShip = data.Ship_Count;
        Cargo_Matrix=data.Cargo_Matrix;
        Empty_Cargo_Matrix=data.Empty_Cargo_Matrix;

        n=size(PORTDIST,2);
        Best_Objective = data.Best_Objective;            
        Total_Income=0;Total_cargocost=0;Total_empty_cargocost=0;Carbon_tax=0;
        for i=1:N
            Total_Income= Total_Income+(1/N)*sum(Cargo_Matrix(1:n,(i-1)*n+1:i*n).*Revenue(1:n,(i-1)*n+1:i*n),'all');         
            Total_cargocost=Total_cargocost+(1/N)*sum(Cargo_Matrix(1:n,(i-1)*n+1:i*n).*full_cargocost(1:n,(i-1)*n+1:i*n),'all');       
            Total_empty_cargocost=Total_empty_cargocost+(1/N)*sum(Empty_Cargo_Matrix(1:n,(i-1)*n+1:i*n).*empty_cargocost(1:n,(i-1)*n+1:i*n),'all');       
            for zzz=1:size(carbontax_parameter,2)
                Carbon_tax=Carbon_tax+carbontax_parameter(1,zzz)*Fuel((i-1)*n+zzz,1);
            end
        end
        Carbon_tax=Carbon_tax/N;
        Total_Fuel_Cost= (1/N)* FuelPrice*Fuel;
        Total_Fixed_Cost= (length(PORTDIST)-1)*(containerCapacity*1.95+5200)+ fixedcost*NumOfShip;
        
        for num=1:size(Speed,1)
            Real_Speed(num,1)=1/Speed(num,1);
        end
        for i=1:N
            total_time=0;
            total_length=0;
            for n=(i-1)*size(PORTDIST,2)+1:i*size(PORTDIST,2)-1
                total_time=total_time+PORTDIST(1,n-(i-1)*size(PORTDIST,2))/Real_Speed(n,1);
                total_length=sum(PORTDIST);
            end
            average_Speed(i,1)=total_length/total_time;
        end
    end
else
    disp('NotFound.');
    Best_Objective=0;
    Speed=0;
    Fuel=0;
    Port_Decision=0;
    Fuel_Consume=0;
    Fuel_Remain=0;
    Travel_Time=0;
    Ship_Arrival_Time=0;
    NumOfShip=0;
    Total_Fuel_Cost=0;
    Total_Fixed_Cost=0;
    Real_Speed=0;
    Cargo_Matrix=0;
    Empty_Cargo_Matrix=0;
    Total_Income=0;
    Total_cargocost=0;
    Total_empty_cargocost=0;

end


