# cloud-vm-placement-simulator-drl-vs-heuristics
MATLAB based simulation environment for dynamic VM placement in cloud data centres. Evaluates a Deep Reinforcement Learning  agent (DQN) against heuristic methods (First Fit, Best Fit, Worst Fit) for the Bin-Packing problem enabling fair performance comparison and  research extension.

## Problem Statement
Initial VM placement is crucial for energy efficiency and resource management in cloud data centres. Traditionally, simple heuristic methods such as First Fit and Best Fit have been used due to their simplicity and reasonable performance. However, recent developments in Deep Reinforcement Learning (DRL) have enabled agents to perform these tasks more effectively. This project evaluates the widely used DRL agent, DQN, against traditional heuristic methods—First Fit, Best Fit, and Worst Fit—focusing on energy consumption, multi-objective optimization, and allocation time.

## Features
Matlab based simulation environment for dynamic VM placement in a cloud datacentre
Implements multiple initial VM placement strategies, including DQN agent, First Fit, Best Fit, and Worst Fit methods.
Evaluates VM placement strategies using key performance metrics: total energy consumption, multi-objective optimization, allocation time, and success rate.
Provides live terminal logs to monitor simulation progress and outputs text files with a summary of final results for analysis.
Provides configurable files for adjusting data centre characteristics and simulation parameters.
Designed using Object-Oriented Programming (OOP) principles, allowing easy extension to include new agents or custom VM allocation methods.

## Folder structure and key files
-main_setup.m  -> run this file first to add and ensure all file paths exist
-config/thermal_dqn_config.m -> configuration file for data centre simulation and reseurce parameters
-data/  -> csv file for VM traces
-results/ -> store text based results for each allocation strategy
-run_strategy_name_allocation/  -> contain scripts to run a single simulation run or multiple runs at once

## usage
### use the DQN agent for allocation
1.	Edit the agent parameters in “agents/create_dqn_agent.m”
2.	Run the file “create_dqn_agent.m”
3.	Train the agent
4.	Include the file name of trained agent in “run_DQN_allocation/run_DQN_allocation.m” to run the simulation a single time
5.	Include the file name in “run_DQN_allocation/run_DQN_allocation_return.m” and run the file “run_DQN_multiple.m” to run the simulation multiple times as required.
6.	The results will be stored in “results/DQN”
   
### use the heuristic methods for allocation
1.	Run the “run_(allocation_method)_allocation/run_(allocation_method)_allocation.m” to run the chosen method a single time.
2.	Run the “run_(allocation_method)_allocation/run_(allocation_method)_multiple.m” to run the chosen method multiple times.
3.	The results will be stored in “results/allocation_method/”

## Future Work
- Extend the environment for multiple cloud data centers
- Integrate other DRL algorithms for comparison

## Contact
Developed by Visura Chandula(www.linkedin.com/in/visurachandula)


   
