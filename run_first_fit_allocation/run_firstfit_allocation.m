function run_firstfit_allocation()
% RUN_FIRSTFIT_ALLOCATION - Use First-Fit for VM allocation/evaluation.

    fprintf('=== First-Fit VM Allocation Deployment ===\n\n');
    % Load config (same as DQN run)
    config = thermal_dqn_config();

    % Environment setup
    env = VMEnvironment(config);

    fprintf('✓ Environment ready\n');

    % Create First-Fit agent
    agent = create_firstfit_agent(config);

    % Reset env for fresh start
    obs = reset(env);
    total_reward = 0;
    step_count = 0;

    allocation_start_time = tic;

    while step_count < config.max_steps_per_episode
        action = agent.getAction(obs);

        [obs, reward, done] = env.step(action);

        total_reward = total_reward + reward;
        step_count = step_count + 1;

        if mod(step_count, 20) == 0
            fprintf('Step %d: Cumulative reward = %.2f\n', step_count, total_reward);
        end

        if done
            fprintf('\nSimulation completed naturally at step %d\n', step_count);
            break;
        end
    end

    allocation_time_seconds = toc(allocation_start_time);

    placement_stats.successful = env.EpisodeStats.successful_placements;
    placement_stats.rejected   = env.EpisodeStats.rejections;
    total_requests = placement_stats.successful + placement_stats.rejected;
    placement_stats.total_energy = env.EpisodeStats.total_energy;

    % Results summary
    fprintf('\n=== Allocation Results (First-Fit) ===\n');
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
    fprintf('Total energy consumed: %.2f kWh\n', placement_stats.total_energy);
            fprintf('========================\n\n');

    % Save results to files for fair comparison
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    results_folder = fullfile('results', 'First_Fit');
    mat_folder = fullfile(results_folder, 'Matlab_format');
    txt_folder = fullfile(results_folder, 'Text_format');

    results_mat = fullfile(mat_folder, sprintf('firstfit_results_%s.mat', timestamp));
    save(results_mat, 'total_reward', 'step_count', 'placement_stats', ...
         'allocation_time_seconds', 'total_requests');
    
    results_txt = fullfile(txt_folder, sprintf('firstfit_results_%s.txt', timestamp));
    save_allocation_results_to_text(results_txt, step_count, allocation_time_seconds, ...
        total_reward, placement_stats, total_requests, 'First-Fit');
    
    fprintf('\n✓ Results saved to: %s\n', results_mat);
    fprintf('✓ Text report saved to: %s\n', results_txt);
    fprintf('\n=== First-Fit Allocation Complete ===\n');



    
end
