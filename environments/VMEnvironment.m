classdef VMEnvironment < rl.env.MATLABEnvironment
    % VMEnvironment - RL environment for VM placement with time-aware lifecycle
    
    properties
        Config              % Configuration from thermal_dqn_config
        ServerStates        % Current server states [num_servers x 4]
        CurrentVM           % Current VM request to place
        StepCount           % Number of simulation steps taken
        CurrentStep         % Current simulation step (time)
        VMList              % Array of all VMs from traces
        ActiveVMs           % Array of currently running VMs
        NextVMIndex         % Index of next VM to consider
        TraceStats          % Statistics about loaded traces
        EpisodeStats        % Statistics for current episode
        SimulationStartTime
    end
    
    methods
        function this = VMEnvironment(config)
            % Constructor
            fprintf('Creating VM Environment...\n');
            
            % Define observation and action spaces
            state_size = config.state_size;
            obsInfo = rlNumericSpec([state_size 1], ...
                'LowerLimit', zeros(state_size, 1), ...
                'UpperLimit', ones(state_size, 1));
            
            actInfo = rlFiniteSetSpec(0:(config.num_actions-1));
            
            % Initialize environment
            this = this@rl.env.MATLABEnvironment(obsInfo, actInfo);
            this.Config = config;
            
            % Load VM traces
            if config.use_traces && exist(config.trace_file, 'file')
                [this.VMList, this.TraceStats] = load_vm_traces(config);
            else
                fprintf('Warning: No traces found, using random generation\n');
                this.VMList = [];
                this.TraceStats = struct();
            end
            
            % Initialize episode stats
            this.EpisodeStats = struct();
            
            fprintf('✓ VM Environment created successfully\n');
            reset(this);
        end
        
        function [observation, reward, isDone] = step(this, action)
            if iscell(action)
                action = action{1};
            end

            
            
            % Process VM placement decision
            if isempty(this.CurrentVM)
                % No VM to place, just advance time
                reward = 0;
            elseif action == 0
                % Reject VM
                reward = this.Config.rejection_penalty;
                this.EpisodeStats.rejections = this.EpisodeStats.rejections + 1;
                fprintf('Step %d: VM%d rejected. Reward: %.2f\n', ...
                    this.CurrentStep, this.CurrentVM.id, reward);
            else
                % Try to place VM on server
                server_id = action;
                [success, reward] = this.place_vm_on_server(server_id);
                
                if success
                    this.EpisodeStats.successful_placements = this.EpisodeStats.successful_placements + 1;
                    fprintf('Step %d: VM%d placed on server %d. Reward: %.2f\n', ...
                        this.CurrentStep, this.CurrentVM.id, server_id, reward);
                else
                    this.EpisodeStats.rejections = this.EpisodeStats.rejections + 1;
                    fprintf('Step %d: VM%d placement failed on server %d. Reward: %.2f\n', ...
                        this.CurrentStep, this.CurrentVM.id, server_id, reward);
                end
            end
            
            % Advance simulation time
            this.advance_simulation_time();
            
            % Check episode termination
            isDone = this.check_episode_done();
            
            % Get new observation
            observation = this.get_observation();
        end
        
        function initialObs = reset(this)
            fprintf('Resetting environment...\n');
            
            % Initialize server states
            this.ServerStates = zeros(this.Config.num_servers, 5);
            this.ServerStates(:,5) = this.Config.idle_power_per_server / this.Config.peak_power_per_server;
            
            % Reset time and VM tracking
            this.CurrentStep = 0;
            this.StepCount = 0;
            this.ActiveVMs = VM.empty(0, 1);
            this.CurrentVM = [];
            
            % RANDOMIZE STARTING POSITION IN VM TRACES
            if ~isempty(this.VMList)
                max_start_index = max(1, length(this.VMList) - this.Config.max_steps_per_episode);
                this.NextVMIndex = randi(max_start_index);
                
                % SOLUTION: Store the reference time but use relative steps
                this.SimulationStartTime = this.VMList(this.NextVMIndex).start_step;
                this.CurrentStep = 0;  % Always start episode steps at 0
                
                fprintf('Starting from VM index: %d, reference time: %d\n', ...
                    this.NextVMIndex, this.SimulationStartTime);
            else
                this.SimulationStartTime = 0;
                this.CurrentStep = 0;
                this.NextVMIndex = 1;
            end
            
            
            % Reset episode statistics
            this.EpisodeStats.successful_placements = 0;
            this.EpisodeStats.rejections = 0;
            this.EpisodeStats.total_energy = 0;
            this.EpisodeStats.peak_servers_used = 0;
            
            % Get first VM request
            this.get_next_vm_request();
            
            initialObs = this.get_observation();
            fprintf('✓ Environment reset complete\n');
        end

    end
    
    methods (Access = private)
        function observation = get_observation(this)
            % Build observation vector for DQN agent
            
            % Server features (normalized to 0-1)
            server_features = this.ServerStates(:);  % Flatten to column vector
    
            
            

            
            % Current VM features
            if ~isempty(this.CurrentVM)
                vm_features = [
                    this.CurrentVM.cpu_needed;
                    this.CurrentVM.memory_needed;
                    this.CurrentVM.hdd_needed;
                    this.CurrentVM.ssd_needed;
                ];
            else
                vm_features = zeros(4, 1);
            end
            
            % Global features
            total_power = sum(this.ServerStates(:, 5));
            max_power = this.Config.num_servers * this.Config.peak_power_per_server;
            power_normalized = total_power / max_power;
            
            time_normalized = this.CurrentStep / this.Config.max_simulation_steps;
            
            global_features = [power_normalized; time_normalized];
            
            % Combine all features
            observation = [server_features; vm_features; global_features];

                    
        end
        
        function get_next_vm_request(this)
            this.CurrentVM = [];
            
            if this.Config.use_traces && ~isempty(this.VMList)
                % Convert relative episode time to absolute simulation time
                absolute_time = this.SimulationStartTime + this.CurrentStep;
                
                while this.NextVMIndex <= length(this.VMList)
                    vm = this.VMList(this.NextVMIndex);
                    if vm.check_should_start(absolute_time)  % Use absolute time
                        this.CurrentVM = vm;
                        this.NextVMIndex = this.NextVMIndex + 1;
                        break;
                    elseif vm.start_step > absolute_time
                        break;
                    else
                        this.NextVMIndex = this.NextVMIndex + 1;
                    end
                end
            else
                this.generate_random_vm();
            end
        end

        
        function generate_random_vm(this) %For testing only
            % Generate random VM request (fallback when no traces)
            cpu_options = [0.1, 0.25, 0.5, 1.0];
            memory_options = [0.1, 0.25, 0.5, 0.75, 1.0];
            storage_options = [0.1, 0.2, 0.4, 0.6, 0.8];
            
            cpu = cpu_options(randi(length(cpu_options)));
            memory = memory_options(randi(length(memory_options)));
            storage = storage_options(randi(length(storage_options)));
            
            % Random duration (1-24 hours in steps)
            duration_hours = 1 + rand() * 23;
            duration_steps = ceil(duration_hours * 60 / this.Config.minutes_per_step);
            
            vm_id = randi(100000);
            this.CurrentVM = VM(vm_id, cpu, memory, storage, ...
                              this.CurrentStep / this.Config.steps_per_day, ...
                              (this.CurrentStep + duration_steps) / this.Config.steps_per_day, ...
                              this.Config.steps_per_day);
        end
        
        function [success, reward] = place_vm_on_server(this, server_id)
            % Attempt to place current VM on specified server
            
            if isempty(this.CurrentVM)
                success = false;
                reward = 0;
                return;
            end
            
            % Check resource availability (fractional units)
            current_cpu = this.ServerStates(server_id, 1);
            current_memory = this.ServerStates(server_id, 2);
            current_hdd = this.ServerStates(server_id, 3);
            current_ssd = this.ServerStates(server_id, 4);
            
            new_cpu = current_cpu + this.CurrentVM.cpu_needed;
            new_memory = current_memory + this.CurrentVM.memory_needed;
            new_hdd = current_hdd + this.CurrentVM.hdd_needed;
            new_ssd = current_ssd + this.CurrentVM.ssd_needed;
            
            % Check if placement is feasible
            if (new_cpu <= 1.0) && (new_memory <= 1.0) && (new_hdd <= 1.0) && (new_ssd <= 1.0)
                success = true;
                
                % Update server state
                this.ServerStates(server_id, 1) = new_cpu;
                this.ServerStates(server_id, 2) = new_memory;
                this.ServerStates(server_id, 3) = new_hdd;
                this.ServerStates(server_id, 4) = new_ssd;
                
                % Update power consumption (linear with CPU utilization)
                this.ServerStates(server_id,5) = ...
                   (this.Config.idle_power_per_server + ...
                   (this.Config.peak_power_per_server - this.Config.idle_power_per_server) * new_cpu) ...
                   / this.Config.peak_power_per_server;

                
                % Place VM and add to active list
                this.CurrentVM.place_on_server(server_id);
                this.ActiveVMs(end+1) = this.CurrentVM;
                
                % Calculate reward
                reward = this.calculate_placement_reward(server_id, new_cpu);
                
            else
                success = false;
                reward = this.Config.rejection_penalty;
            end
        end
        
        

        function reward = calculate_placement_reward(this, server_id, cpu_util)
            % Calculate reward for successful VM placement
            
            base_reward = this.Config.placement_reward;  % +20
            
            % SLA VIOLATION PENALTIES
            sla_penalty = 0;
            if cpu_util > 0.85
                % Critical zone: High SLA violation risk
                sla_penalty = 15 * (cpu_util - 0.85);  % Up to -3 penalty
            elseif cpu_util > 0.70
                % Warning zone: Moderate SLA violation risk  
                sla_penalty = 8 * (cpu_util - 0.70);   % Up to -1.2 penalty
            end
            
            % === ENERGY CONSUMPTION PENALTY ===
            
            % Higher CPU = higher power consumption
            energy_penalty = cpu_util * cpu_util * 5;  % Quadratic penalty (0 to -5)
            
            %COMBINED WEIGHTED PENALTY ===
            total_penalty = (this.Config.sla_weight * sla_penalty) + ...
                            (this.Config.energy_weight * energy_penalty);
            
            % FINAL REWARD CALCULATION ===
            reward = base_reward - total_penalty;
            
            % === SAFETY CHECK: Ensure feasible > rejection ===
            % Worst case: cpu_util = 1.0 gives penalty ≈ -6.8
            % Final reward ≈ 20 - 6.8 = 13.2 > rejection_penalty (-10)
            reward = max(reward, this.Config.max_feasible_penalty);
        end

        
    

        function advance_simulation_time(this)
            this.CurrentStep = this.CurrentStep + 1;
            this.StepCount = this.StepCount + 1;
            
            % Remove ended VMs
            this.remove_ended_vms();
            
            % Calculate total actual power consumption
            cpu_utilizations = this.ServerStates(:, 1);
            actual_powers = this.Config.idle_power_per_server + ...
                (this.Config.peak_power_per_server - this.Config.idle_power_per_server) .* cpu_utilizations;
            
            total_power_watts = sum(actual_powers);
            
            % Energy = Power × Time
            time_interval_hours = this.Config.minutes_per_step / 60;
            energy_this_step_kwh = total_power_watts * time_interval_hours / 1000;
            
            % Accumulate energy
            this.EpisodeStats.total_energy = this.EpisodeStats.total_energy + energy_this_step_kwh;
            
            % Update other stats
            active_servers = sum(cpu_utilizations > 0);
            this.EpisodeStats.peak_servers_used = max(this.EpisodeStats.peak_servers_used, active_servers);
            
            this.get_next_vm_request();
        end

        
        function remove_ended_vms(this)
            % Remove VMs that have reached their end time
            vms_to_remove = [];
            absolute_time = this.SimulationStartTime + this.CurrentStep;
            
            for i = 1:length(this.ActiveVMs)
                vm = this.ActiveVMs(i);
                if vm.check_should_end(absolute_time)
                    % Remove VM resources from server
                    server_id = vm.server_id;
                    
                    this.ServerStates(server_id, 1) = max(0, this.ServerStates(server_id, 1) - vm.cpu_needed);
                    this.ServerStates(server_id, 2) = max(0, this.ServerStates(server_id, 2) - vm.memory_needed);
                    this.ServerStates(server_id, 3) = max(0, this.ServerStates(server_id, 3) - vm.hdd_needed);
                    this.ServerStates(server_id, 4) = max(0, this.ServerStates(server_id, 4) - vm.ssd_needed);
                    
                    % Update power consumption
                    new_cpu_util = this.ServerStates(server_id, 1);
                    this.ServerStates(server_id, 5) = (this.Config.idle_power_per_server + ...
                        (this.Config.peak_power_per_server - this.Config.idle_power_per_server) * new_cpu_util)...
                        / this.Config.peak_power_per_server;
                    
                    vm.remove_from_server();
                    vms_to_remove(end+1) = i;
                    
                    fprintf('Step %d: VM%d ended, removed from server %d\n', ...
                        this.CurrentStep, vm.id, server_id);
                end
            end
            
            % Remove ended VMs from active list
            this.ActiveVMs(vms_to_remove) = [];
        end
        
        function isDone = check_episode_done(this)
            % Check if episode should terminate
            isDone = (this.CurrentStep >= this.Config.max_simulation_steps) || ...
                     (this.StepCount >= this.Config.max_steps_per_episode) || ...
                     (this.Config.use_traces && isempty(this.CurrentVM) && ...
                      this.NextVMIndex > length(this.VMList));
            
            if isDone
                this.print_episode_summary();
            end
        end
        
        function print_episode_summary(this)
            % Print summary of episode performance
            total_requests = this.EpisodeStats.successful_placements + ...
                           this.EpisodeStats.rejections;
            
            fprintf('\n=== Episode Summary ===\n');
            fprintf('Total VM requests: %d\n', total_requests);
            fprintf('Successful placements: %d (%.1f%%)\n', ...
                this.EpisodeStats.successful_placements, ...
                this.EpisodeStats.successful_placements / max(1, total_requests) * 100);
            fprintf('Rejections: %d (%.1f%%)\n', ...
                this.EpisodeStats.rejections, ...
                this.EpisodeStats.rejections / max(1, total_requests) * 100);
            fprintf('Peak servers used: %d/%d (%.1f%%)\n', ...
                this.EpisodeStats.peak_servers_used, this.Config.num_servers, ...
                this.EpisodeStats.peak_servers_used / this.Config.num_servers * 100);
            fprintf('Total energy consumed: %.2f kWh\n', this.EpisodeStats.total_energy);
            fprintf('========================\n\n');
        end
    end
end
