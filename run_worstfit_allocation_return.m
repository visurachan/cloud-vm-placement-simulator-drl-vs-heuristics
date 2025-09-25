function results = run_worstfit_allocation_return()
    % RUN_WORSTFIT_ALLOCATION_RETURN - Perform one Worst-Fit VM allocation and return results struct.
    config = thermal_dqn_config();
    env = VMEnvironment(config);
    agent = create_worstfit_agent(config);

    obs = reset(env);
    total_reward = 0;
    step_count = 0;
    tStart = tic;

    while step_count < config.max_steps_per_episode
        action = agent.getAction(obs);
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
end
