import numpy as np
import random
import pandas as pd
from openpyxl import Workbook
import sys
import json
from gurobipy import Model, GRB, quicksum
import itertools
from openpyxl import Workbook, load_workbook
import scipy.io
import argparse
import tempfile



if len(sys.argv) != 2:
    print("Usage: python your_script.py <path_to_json_file>")
    sys.exit(1)

json_file_path = sys.argv[1]


try:
    with open(json_file_path, 'r') as f:
        input_params = json.load(f)
    print("pythonSuccess:")
except FileNotFoundError:
    print("pythonError")
except json.JSONDecodeError:
    print("pythonFail")


n = input_params["n"]
m = input_params["m"]
segments = [i for i in range(m)]  
distance = input_params["distance"]
fuel_cost = input_params["fuel_cost"]
min_port_time = input_params["min_port_time"]
earliest_arrival = input_params["earliest_arrival"]
latest_arrival = input_params["latest_arrival"]
W_3 = input_params["W_3"]
fixed_cost = input_params["fixed_cost"]
W = input_params["W"]
capacity = input_params["capacity"]
coefficient1 = input_params["coefficient1"]
coefficient2 = input_params["coefficient2"]
total_weight = input_params["total_weight"]
ports = input_params["ports"]
demand = input_params["DEMAND"]
revenue = input_params["REVENUE"]
empty_cargo_cost = input_params["empty_cargo_cost"]
full_cargo_cost = input_params["full_cargo_cost"]
parameterfuel = input_params["parameterfuel"]
carbontax_parameter=input_params["carbontax_parameter"]
N=1
coefficient1=20
coefficient2=2.3
Temp_NumOfShip=input_params["Temp_NumOfShip"]











def create_model(ports, segments):
    mdl = Model('Bunker_Fuel_And_Cargo_Flow_Optimization')
    mdl.setParam('NonConvex', 1)
    mdl.setParam('LogFile', 'gurobi.log')
    speed = mdl.addVars(n*N, name='Speed', vtype=GRB.CONTINUOUS, lb=0.04, ub=0.066666667 ) 
    fuel = mdl.addVars(n*N, vtype=GRB.CONTINUOUS, name='Fuel')  
    port_decision = mdl.addVars(n*N, vtype=GRB.BINARY, name='Port_Decision') 
    ship_count = mdl.addVar(vtype=GRB.INTEGER, lb=1, ub=300, name='Ship_Count') 
    total_fuel_cost = mdl.addVar(name='Total_Fuel_Cost', vtype=GRB.CONTINUOUS) 
    total_fixed_cost = mdl.addVar(name='Total_Fixed_Cost', vtype=GRB.CONTINUOUS) 
    carbon_tax1 = mdl.addVar(name='Carbon_Tax', vtype=GRB.CONTINUOUS)  
    cargo = mdl.addVars(n, n*N, lb=0, vtype=GRB.INTEGER, name="cargo") 
    empty_cargo = mdl.addVars(n, n*N, lb=0, vtype=GRB.INTEGER, name="empty_cargo") 
    Number_of_boxes_in_ship = mdl.addVars(n, N, lb=0, vtype=GRB.INTEGER, name="Number_of_boxes_in_ship") 

    return mdl, speed, fuel, port_decision, ship_count, total_fuel_cost, total_fixed_cost, cargo, empty_cargo, Number_of_boxes_in_ship,carbon_tax1



def set_objective(mdl, fuel, fuel_cost1, ship_count, fixed_cost1, total_fuel_cost, total_fixed_cost, cargo1, revenue1,
                  empty_cargo1,carbon_tax1):
    fuel_cost_sum = quicksum( (1/N) *fuel[i+j*n] * float(fuel_cost1[i+j*n]) for i in range(n) for j in range(N) )  
    totalfuel_consume = quicksum((1/N) *fuel[i] * 1 for i in range(n*N))  
    totalfuel_carbontax = quicksum((1/N) *fuel[i+j*n] * carbontax_parameter[i] for i in range(n) for j in range(N))  
    fixed_cost_sum = fixed_cost1 * Temp_NumOfShip  
    port_cost_sum= (m)*(1.95*capacity+5200)
    empty_transport_cost = quicksum( (1/N)*
        empty_cargo1[i, j] * (empty_cargo_cost[i][j]) for i in range(n) for j in range(n*N)) 
    mdl.addConstr(total_fuel_cost == fuel_cost_sum, "Total_Fuel_Cost_Constraint")
    mdl.addConstr( carbon_tax1  == totalfuel_carbontax, "CarbonTax_Constraint")  
    mdl.addConstr(total_fixed_cost == fixed_cost_sum, "Total_Fixed_Cost_Constraint")
    mdl.setObjective(
        quicksum((1/N)*cargo1[i, j] * (revenue1[i][j] - full_cargo_cost[i][j]) for i in range(n) for j in range(n*N)) -
        (fuel_cost_sum + fixed_cost_sum+port_cost_sum + empty_transport_cost+carbon_tax1), GRB.MAXIMIZE)



def add_constraints(mdl, ports1, segments1, speed, fuel, port_decision, ship_count, distance1, min_port_time1,
                    earliest_arrival1, latest_arrival1, W1, W_31, cargo, empty_cargo, Number_of_boxes_in_ship,carbon_tax1):
    fuel_consume = mdl.addVars(N*n, lb=0, name='Fuel_Consume', vtype=GRB.CONTINUOUS)  
    fuel_remain = mdl.addVars(N*n, lb= 0, ub= W, vtype=GRB.CONTINUOUS, name='Fuel_Remain')  
    travel_time = mdl.addVar(lb=0, vtype=GRB.CONTINUOUS, name='Travel_Time')  
    ship_arrival_time = mdl.addVars(len(ports1) + 1, lb=0, name='Ship_Arival_Time', vtype=GRB.INTEGER) 
    cargo_weight_in_ship = mdl.addVars(n,N, lb=0, name='cargo_weight_in_ship', vtype=GRB.CONTINUOUS)

    v_points1 =[0.04, 	0.040684, 	0.041368, 	0.042051, 	0.042735, 	0.043419, 	0.044103, 	0.044786, 	0.04547, 	0.046154, 	0.046838, 	0.047521, 	0.048205, 	0.048889, 	0.049573, 	0.050256, 	0.05094, 	0.051624, 	0.052308, 	0.052991, 	0.053675, 	0.054359, 	0.055043, 	0.055726, 	0.05641, 	0.057094, 	0.057778, 	0.058462, 	0.059145, 	0.059829, 	0.060513, 	0.061197, 	0.06188, 	0.062564, 	0.063248, 	0.063932, 	0.064615, 	0.065299, 	0.065983, 	0.066667 ]
    base_parameter=[0.426014, 	0.410994, 	0.396741, 	0.383204, 	0.370335, 	0.358093, 	0.346438, 	0.335333, 	0.324744, 	0.31464, 	0.304992, 	0.295773, 	0.286959, 	0.278526, 	0.270453, 	0.26272, 	0.255308, 	0.2482, 	0.24138, 	0.234831, 	0.228541, 	0.222496, 	0.216684, 	0.211092, 	0.20571, 	0.200528, 	0.195536, 	0.190724, 	0.186085, 	0.18161, 	0.177292, 	0.173123, 	0.169097, 	0.165207, 	0.161448, 	0.157813, 	0.154297, 	0.150896, 	0.147604, 	0.144416]
    coefficients1 = [x * parameterfuel for x in base_parameter]

  
    for j in range(N):
        for i in range(len(segments1)):
            v_coef1 = mdl.addVar(vtype=GRB.CONTINUOUS, name=f"coef1_{i}")
            mdl.addGenConstrPWL(speed[i+j*n], v_coef1, v_points1, coefficients1,
                                name=f"pwl_coef1_{i}")  
            mdl.addConstr(fuel_consume[i+j*n] == distance1[i] * v_coef1, "circleConstraint")  
 
    for i in range(n*N):
        mdl.addConstr(fuel[i] >= 0.1*W1* port_decision[i])
  
    for i in range(n*N):
        mdl.addConstr(fuel[i] <= W1 * port_decision[i])
 
    for i in range(n*N):
        mdl.addConstr(fuel_remain[i] <= W1)
    for i in range(n*N):
        mdl.addConstr(fuel_remain[i] >= 0.1*W1)       

    for i in range(n*N):
        mdl.addConstr(fuel_remain[i] >= fuel_consume[i] + W_31)

    for t in range(N):
        for i in range(len(ports1)):
            if i == 0:
                mdl.addConstr(fuel_remain[i+t*n] == fuel[i+t*n])
            else:
                mdl.addConstr(fuel_remain[i+t*n] == (fuel_remain[i +t*n- 1] - fuel_consume[i+t*n - 1] + fuel[i+t*n] - W_31))

    for t in range(N):
        mdl.addConstr(
            travel_time == sum(distance1[i] * speed[i+t*n] for i in range(n)) + min_port_time1 * len(segments1))
        mdl.addConstr(travel_time <= 168 * ship_count)
        mdl.addConstr(ship_count<=Temp_NumOfShip)



    for i in range(n):
        for j in range(n*N):
            mdl.addConstr(cargo[i, j] <= demand[i][j])
  
    for t in range(N):
        for i in range( n):
            if i == 0:
                mdl.addConstr(Number_of_boxes_in_ship[i,t] == quicksum(cargo[i, j] + empty_cargo[i, j] for j in range(n*t,n*(t+1))))
            else:
                mdl.addConstr(Number_of_boxes_in_ship[i,t] == Number_of_boxes_in_ship[i - 1,t] + 
                              quicksum(cargo[i, j] + empty_cargo[i, j] for j in range(n*t,n*(t+1)) ) - 
                              quicksum( cargo[j, i+n*t] + empty_cargo[j, i+n*t] for j in range(n) ))
            mdl.addConstr(Number_of_boxes_in_ship[i,t] <= capacity)
 
    for t in range(N):
        for i in range( n):
            if i == 0:
                mdl.addConstr(cargo_weight_in_ship[i,t] == quicksum(cargo[i, j] * coefficient1 + empty_cargo[i, j] * coefficient2 for j in range(n*t,n*(t+1))))
            else:
                mdl.addConstr(cargo_weight_in_ship[i,t] == cargo_weight_in_ship[i - 1,t]
                              + quicksum( cargo[i, j] * coefficient1 + empty_cargo[i, j] * coefficient2 for j in range(n*t,n*(t+1)))
                              - quicksum( cargo[j, i+n*t] * coefficient1 + empty_cargo[j, i+n*t] * coefficient2 for j in range(n))  )
            mdl.addConstr(cargo_weight_in_ship[i,t] + fuel_remain[i+t*n] <= total_weight)


 
    port_indices = {}
    for idx, port in enumerate(ports):
        if port not in port_indices:
            port_indices[port] = []
        port_indices[port].append(idx)


    for t in range(N):
        for port, indices in port_indices.items():
            total_load = quicksum(cargo[i, j] + empty_cargo[i, j] for i in indices for j in range(n*t,n*(t+1) ) )
            total_unload = quicksum(cargo[j, i+n*t] + empty_cargo[j, i+n*t] for i in indices for j in range(n ) )
            mdl.addConstr(total_load == total_unload)



    for i in range(n):
        for j in range(n*N):
            mdl.addConstr(empty_cargo[i, j] >= 0)
  
    for t in range(N):
        for i in range(n):
            mdl.addConstr(empty_cargo[i, t*n+i] == 0)
  
    for t in range(N):
        for i in range(n):
            total_cargo = 0
            total_empty_cargo = 0
            for j in range(i + 1):
                total_cargo += quicksum(cargo[j, k] for k in range(n*t,n*(t+1))) - quicksum(cargo[k, j+n*t] for k in range(n))
                total_empty_cargo += quicksum(empty_cargo[j, k] for k in range(n*t,n*(t+1))) - quicksum(
                    empty_cargo[k, j+n*t] for k in range(n))
                mdl.addConstr(total_cargo <= capacity)
                mdl.addConstr(total_empty_cargo <= capacity)

    for j in range(n*N):
        mdl.addConstr(empty_cargo[n - 1, j] == 0)

    for t in range(N):
        for i in range(n):
            for j in range(n*t,n*t+i):
                mdl.addConstr(empty_cargo[i, j] == 0)

    return fuel_consume, fuel_remain, travel_time, ship_arrival_time,cargo_weight_in_ship




def parse_arguments():
    parser = argparse.ArgumentParser(description='Process optimization parameters')
    parser.add_argument('--params_file', type=str, required=True, 
                       help='Path to the JSON parameters file')
    return parser.parse_args()


def main():

   
        mdl, speed, fuel, port_decision, ship_count, total_fuel_cost, total_fixed_cost, cargo, empty_cargo, Number_of_boxes_in_ship,carbon_tax \
        = create_model(ports, segments)


        set_objective(mdl, fuel, fuel_cost, ship_count, fixed_cost, total_fuel_cost, total_fixed_cost, cargo, revenue,
                      empty_cargo,carbon_tax)
    

        fuel_consume, fuel_remain, travel_time, ship_arrival_time, cargo_weight_in_ship1 = (
            add_constraints(mdl, ports, segments, speed, fuel, port_decision, ship_count, distance,
                            min_port_time, earliest_arrival, latest_arrival, W, W_3, cargo, empty_cargo,
                            Number_of_boxes_in_ship,carbon_tax))
    
    
        mdl.optimize()
    

        if mdl.status == GRB.OPTIMAL:
    
            print("Speed and Fuel:")

            Best_objective = mdl.objVal
            speed_values = [speed[i].X for i in range(len(speed))]
            fuel_values = [fuel[i].X for i in range(len(fuel))]
            port_decision_values = [int(port_decision[i].X) for i in range(len(port_decision))]
            fuel_consume_values = [fuel_consume[i].X for i in range(len(fuel_consume))]
            fuel_remain_values = [fuel_remain[i].X for i in range(len(fuel_remain))]
            #cargo_weight_in_ship_values = [cargo_weight_in_ship1[i,t].X for i in range(len(cargo_weight_in_ship1)) for t in range(N)]
            real_speed = 1 / (np.array(speed_values))
            ship_count_value = ship_count.X
    
    
            print("Cargo Flow:")
            cargo_matrix = [[0 for _ in range(n*N)] for _ in range(n)]
            empty_cargo_matrix = [[0 for _ in range(n*N)] for _ in range(n)]
    
    
            for i in range(n): 
                for j in range(n*N):
                    if (i, j) in cargo:
                        cargo_matrix[i][j] = cargo[i, j].X
                    if (i, j) in empty_cargo:
                        empty_cargo_matrix[i][j] = empty_cargo[i, j].X
            
            cargo_matrix_values = [[cargo[i, j].X if (i, j) in cargo else 0 for j in range(n*N)] for i in range(n)]
            empty_cargo_matrix_values = [[empty_cargo[i, j].X if (i, j) in empty_cargo else 0 for j in range(n*N)] for i in range(n)]
            
            Total_result = {
                "Best_Objective": mdl.objVal,  
                "Speed": [speed[i].X for i in range(len(speed))],
                "Fuel": [fuel[i].X for i in range(len(fuel))],
                "Port_Decision": [int(port_decision[i].X) for i in range(len(port_decision))],
                "Fuel_Consume": [fuel_consume[i].X for i in range(len(fuel_consume))],
                "Fuel_Remain": [fuel_remain[i].X for i in range(len(fuel_remain))],
                "Ship_Count": ship_count.X,
                "Cargo_Matrix": cargo_matrix_values,
                "Empty_Cargo_Matrix": empty_cargo_matrix_values  
            }
            print(f"result:", json.dumps(Total_result)) 



            
        else:
           
            print("No optimal solution found.")



if __name__ == '__main__':
    main()