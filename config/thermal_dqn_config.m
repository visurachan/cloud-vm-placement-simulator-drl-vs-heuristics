function config = thermal_dqn_config()
    %Configuration for DQN-based VM placement
    
    fprintf('Loading VM Placement Configuration...\n');
    
    %% Data Center Setup
    config.num_servers = 800;              % Number of physical servers
    
    % Server capacities (fractional units - 1.0 = 100% of server)
    config.cpu_per_server = 1.0;           % 1.0 CPU unit per server
    config.memory_per_server = 1.0;        % 1.0 Memory unit per server  
    config.ssd_per_server = 1.0;       % 1.0 SSD Storage unit per server
    config.hdd_per_server = 1.0;       % 1.0 SSD Storage unit per server
    
    %% Power Model
    config.idle_power_per_server = 132.5;  % Watts when idle
    config.peak_power_per_server = 530;    % Watts at 100% CPU
    
    %% Time Configuration (5-minute steps)
    config.minutes_per_step = 5;           % Each step = 5 minutes
    config.steps_per_hour = 12;            % 60/5 = 12
    config.steps_per_day = 288;            % 24 * 12 = 288
    config.max_simulation_days = 1.0;      % Simulate 1 day per episode
    config.max_simulation_steps = config.steps_per_day * config.max_simulation_days;
    
    %% State Space Configuration
    config.server_features = 5;            % [CPU_util, Memory_util, SSD_util,HDD_util, Power]
    config.vm_features = 4;                % [CPU_need, Memory_need, SSD_need, HDD_needed]
    config.global_features = 2;            % [Total_power, Current_time]
    
    % Total state size
    config.state_size = config.num_servers * config.server_features + ...
                        config.vm_features + config.global_features;
    
    %% Action Space
    config.num_actions = config.num_servers + 1;  % 120 servers + reject option
    
    %% VM Trace Configuration
    config.use_traces = true;               % Use real traces vs random
    config.trace_file = 'data/eval.csv';
    config.trace_downsample_rate =  0.001;   % Use 10% of original traces
    config.trace_time_scale = 1/288;        % Convert day fractions to steps
    
    %% Reward Configuration
    config.placement_reward = 20;          % Base reward for successful placement
    config.rejection_penalty = -10;        % Your handled rejection penalty
    config.sla_weight = 0.6;               % Weight for SLA violations (higher priority)
    config.energy_weight = 0.4;            % Weight for energy efficiency
    config.max_feasible_penalty = -8;      % Ensures feasible > rejection penalty

    %% Training Configuration
    config.max_episodes = 1000;            % Number of training episodes
    config.max_steps_per_episode = 200;    % Steps per episode (~17 hours simulated)
    
    fprintf('✓ Configuration loaded successfully\n');
end
