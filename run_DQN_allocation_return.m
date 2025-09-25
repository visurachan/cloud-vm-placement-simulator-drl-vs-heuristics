function [results, agent_file] = run_DQN_allocation_return()
    % RUN_DQN_ALLOCATION_RETURN - Executes one DQN VM allocation and returns results as struct.

    fprintf('=== DQN VM Allocation Deployment ===\n\n');
    % Load the most recent trained agent
    agent_files = dir('initial_trained_agent_2025-08-21_18-48-21.mat');
    if isempty(agent_files)
        error('No trained agent file found.');
    end
    [~, newest_idx] = max([agent_files.datenum]);
    agent_file = agent_files(newest_idx).name;

    fprintf('Loading agent from: %s\n', agent_file);
    load(agent_file, 'agent');
    config = thermal_dqn_config();
    fprintf('✓ Trained agent loaded successfully\n');
    env = VMEnvironment(config);

    obs = reset(env);
    total_reward = 0;
    step_count = 0;
    tStart = tic;
    while step_count < config.max_steps_per_episode
        action = getAction(agent, obs);
        [obs, reward, done] = env.step(action);
        total_reward = total_reward + reward;
        step_count = step_count + 1;
        if done
            break;
        end
    end
    allocation_time = toc(tStart);

    ps = env.EpisodeStats;
    successful = ps.successful_placements;
    rejected = ps.rejections;
    total_req = successful + rejected;

    % Package results
    results.step_count = step_count;
    results.allocation_time_sec = allocation_time;
    results.avg_time_per_step_ms = (allocation_time*1e3) / step_count;
    results.avg_time_per_vm_ms = (allocation_time*1e3) / max(1, total_req);
    results.total_reward = total_reward;
    results.total_requests = total_req;
    results.successful_placements = successful;
    results.rejected_placements = rejected;
    results.success_rate_pct = successful / max(1, total_req) * 100;
    results.rejection_rate_pct = rejected / max(1, total_req) * 100;
    results.total_energy_kWh = ps.total_energy;
    results.agent_file = agent_file; % For traceability
end
