Thank you for visiting this project!

This is a project for solving stochastic programming model optimization problems based on MATLAB and Gurobi. It aims to generate random numbers through Monte Carlo simulation and solve upper and lower bound subproblems using Gurobi. These modules enable the solution of stochastic optimization problems.

├── README.md
├── SAA_of_new_uncertain_main.m   # Matlab main
├── 1.monte_carloA.m              # Monte Carlo simulation function
├── 2.up_subprogram.m             # Upper Bound Problem Solving and Result Feedback -- Submodule 1
├──────2.1.new_function_up.py     # Subfunction used for upper bound solving
├── 3.low_subprogram.m            # Solving the Lower bound problem and providing feedback on results -- Submodule 2
├──────3.1.new_function_low.py    # Subfunction used for Lower bound solving
