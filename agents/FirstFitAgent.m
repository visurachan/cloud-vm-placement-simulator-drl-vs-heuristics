classdef FirstFitAgent < handle
    properties
        Config
    end

    methods
        function this = FirstFitAgent(config)
            this.Config = config;
        end

        %server index or 0 for reject
        function action = getAction(this, observation)
           
            % [all server_features(:); vm_features; global_features]
            n_servers = this.Config.num_servers;
            server_features = reshape(observation(1:n_servers*5), [5, n_servers])'; % [n_servers x 5]
            vm_obs = observation(n_servers*5 + 1 : n_servers*5 + 4);
            cpu_needed    = vm_obs(1);
            memory_needed = vm_obs(2);
            ssd_needed    = vm_obs(3);
            hdd_needed    = vm_obs(4);

            % For each server, check if resources are available (all <= 1)
            for server_id = 1:n_servers
                curr_cpu = server_features(server_id, 1);
                curr_mem = server_features(server_id, 2);
                curr_ssd = server_features(server_id, 4);
                curr_hdd = server_features(server_id, 3);
                if (curr_cpu + cpu_needed <= 1.0) && (curr_mem + memory_needed <= 1.0) && ...
                   (curr_ssd + ssd_needed <= 1.0) && (curr_hdd + hdd_needed <= 1.0)
                    action = server_id; % Place VM on this server
                    return;
                end
            end
            action = 0; % If none can host, reject
        end
    end
end
