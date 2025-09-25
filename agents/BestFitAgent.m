classdef BestFitAgent < handle
    properties
        Config
    end

    methods
        function this = BestFitAgent(config)
            this.Config = config;
        end

        % (server index or 0 for reject)
        function action = getAction(this, observation)
 
            % [all server_features(:); vm_features; global_features]
            n_servers = this.Config.num_servers;
            server_features = reshape(observation(1:n_servers*5), [5, n_servers])'; % [n_servers x 5]
            vm_obs = observation(n_servers*5 + 1 : n_servers*5 + 4);
            cpu_needed    = vm_obs(1);
            memory_needed = vm_obs(2);
            ssd_needed    = vm_obs(3);
            hdd_needed    = vm_obs(4);

            best_server = 0;
            best_score = inf; % Lower score = better fit
            
            % Check all servers and find the one with smallest remaining capacity after placement
            for server_id = 1:n_servers
                curr_cpu = server_features(server_id, 1);
                curr_mem = server_features(server_id, 2);
                curr_ssd = server_features(server_id, 4);
                curr_hdd = server_features(server_id, 3);
                
                % Check if placement is feasible
                if (curr_cpu + cpu_needed <= 1.0) && (curr_mem + memory_needed <= 1.0) && ...
                   (curr_ssd + ssd_needed <= 1.0) && (curr_hdd + hdd_needed <= 1.0)
                    
                    % Calculate remaining capacity after placement (lower = better fit)
                    remaining_cpu = 1.0 - (curr_cpu + cpu_needed);
                    remaining_mem = 1.0 - (curr_mem + memory_needed);
                    remaining_ssd = 1.0 - (curr_ssd + ssd_needed);
                    remaining_hdd = 1.0 - (curr_hdd + hdd_needed);
                    
                    % Use sum of remaining resources as fitness score (lower = tighter fit)
                    score = remaining_cpu + remaining_mem + remaining_ssd + remaining_hdd;
                    
                    if score < best_score
                        best_score = score;
                        best_server = server_id;
                    end
                end
            end
            
            action = best_server; % Will be 0 if no server can host 
        end
    end
end
