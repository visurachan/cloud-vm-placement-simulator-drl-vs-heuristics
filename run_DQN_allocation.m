function run_DQN_allocation()
    % RUN_VM_ALLOCATION - Deploy trained DQN agent for VM allocation
    % This script loads a trained agent and uses it for real-time VM placement
    
    fprintf('=== DQN VM Allocation Deployment ===\n\n');
    
    %% Load Trained Agent
    fprintf('Loading trained agent...\n');
    
    % Find the most recent trained agent
    agent_files = dir('training_agent_name.mat');
    if isempty(agent_files)
        fprintf('No trained agent found! Please run train_dqn_vm_allocator() first.\n');
        return;
    end
    
    % Load the newest agent
    [~, newest_idx] = max([agent_files.datenum]);
    agent_file = agent_files(newest_idx).name;
    
    fprintf('Loading agent from: %s\n', agent_file);
    load(agent_file, 'agent');
    config = thermal_dqn_config();
    fprintf('✓ Trained agent loaded successfully\n');
    
    %% Setup Environment
    fprintf('\nSetting up deployment environment...\n');
    env = VMEnvironment(config);
    fprintf('✓ Environment ready\n');
    
    %% Run VM Allocation Simulation WITH TIMING
    fprintf('\n=== Starting VM Allocation Simulation ===\n');
    fprintf('The agent will now allocate VMs using learned policy...\n\n');
    
    % Reset environment for fresh start
    obs = reset(env);
    
    % Simulation statistics
    total_reward = 0;
    step_count = 0;
    
    % START TIMING - Pure allocation time
    allocation_start_time = tic;
    
    % Run allocation simulation
    while step_count < config.max_steps_per_episode
        % Get agent's action (VM placement decision)
        action = getAction(agent, obs);
        
        % Execute action in environment
        [obs, reward, done] = env.step(action);
        
        % Update statistics
        total_reward = total_reward + reward;
        step_count = step_count + 1;
        
        % Display progress every 20 steps
        if mod(step_count, 20) == 0
            fprintf('Step %d: Cumulative reward = %.2f\n', step_count, total_reward);
        end
        
        if done
            fprintf('\nSimulation completed naturally at step %d\n', step_count);
            break;
        end
    end
    
    % END TIMING
    allocation_time_seconds = toc(allocation_start_time);
    
    % Get final stats from environment
    placement_stats.successful = env.EpisodeStats.successful_placements;
    placement_stats.rejected   = env.EpisodeStats.rejections;
    total_requests = placement_stats.successful + placement_stats.rejected;
    placement_stats.total_energy = env.EpisodeStats.total_energy;
    
    %% Display Results
    fprintf('\n=== Allocation Results ===\n');
    fprintf('Simulation Summary:\n');
    fprintf('- Total steps: %d\n', step_count);
    fprintf('- Pure allocation time: %.4f seconds\n', allocation_time_seconds);
    fprintf('- Average time per step: %.4f ms\n', (allocation_time_seconds * 1000) / step_count);
    fprintf('- Average time per VM: %.4f ms\n', (allocation_time_seconds * 1000) / max(1, total_requests));
    fprintf('- Total reward: %.2f\n', total_reward);
    
    fprintf('\nVM Placement Statistics:\n');
    fprintf('- Total VM requests: %d\n', total_requests);
    fprintf('- Successful placements: %d (%.1f%%)\n', ...
        placement_stats.successful, ...
        placement_stats.successful / max(1, total_requests) * 100);
    fprintf('- Rejected VMs: %d (%.1f%%)\n', ...
        placement_stats.rejected, ...
        placement_stats.rejected / max(1, total_requests) * 100);
    fprintf('Total energy consumed: %.2f kWh\n',placement_stats.total_energy);
            fprintf('========================\n\n');
    
    %% Save Results to Files
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    results_folder = fullfile('results', 'DQN');

    mat_folder = fullfile(results_folder, 'Matlab_format');
    txt_folder = fullfile(results_folder, 'Text_format');

   
    results_mat = fullfile(mat_folder, sprintf('allocation_results_%s.mat', timestamp));
    save(results_mat, 'total_reward', 'step_count', 'placement_stats', ...
         'allocation_time_seconds', 'total_requests', 'agent_file');
    
    results_txt = fullfile(txt_folder, sprintf('allocation_results_%s.txt', timestamp));
    save_allocation_results_to_text(results_txt, step_count, allocation_time_seconds, ...
        total_reward, placement_stats, total_requests, agent_file);
    
    fprintf('\n✓ Results saved to: %s\n', results_mat);
    fprintf('✓ Text report saved to: %s\n', results_txt);
    fprintf('\n=== Deployment Complete ===\n');
    
  end

function save_allocation_results_to_text(filename, step_count, allocation_time, ...
    total_reward, placement_stats, total_requests, agent_file)
    % SAVE_ALLOCATION_RESULTS_TO_TEXT - Write allocation results to a text file
    
    fid = fopen(filename, 'w');
    fprintf(fid, 'DQN VM Allocation Results\n');
    fprintf(fid, '========================\n\n');
    fprintf(fid, 'Date: %s\n', datestr(now));
    fprintf(fid, 'Agent File: %s\n\n', agent_file);
    
    fprintf(fid, 'Execution Summary:\n');
    fprintf(fid, '- Total steps: %d\n', step_count);
    fprintf(fid, '- Pure allocation time: %.4f seconds\n', allocation_time);
    fprintf(fid, '- Average time per step: %.4f ms\n', (allocation_time * 1000) / step_count);
    fprintf(fid, '- Average time per VM: %.4f ms\n', (allocation_time * 1000) / max(1, total_requests));
    fprintf(fid, '- Total reward: %.2f\n', total_reward);
    fprintf(fid, '- Average reward per step: %.4f\n\n', total_reward / step_count);
    
    fprintf(fid, 'VM Placement Statistics:\n');
    fprintf(fid, '- Total VM requests: %d\n', total_requests);
    fprintf(fid, '- Successful placements: %d (%.1f%%)\n', ...
        placement_stats.successful, ...
        placement_stats.successful / max(1, total_requests) * 100);
    fprintf(fid, '- Rejected VMs: %d (%.1f%%)\n', ...
        placement_stats.rejected, ...
        placement_stats.rejected / max(1, total_requests) * 100);
    
    fprintf(fid, '- Success rate: %.4f\n', placement_stats.successful / max(1, total_requests));

    fprintf(fid, 'Total energy consumed: %.2f kWh\n', placement_stats.total_energy);
            fprintf('========================\n\n');
    fclose(fid);
end
