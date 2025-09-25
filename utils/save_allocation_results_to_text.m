% Place this in utils if not global/shared already
function save_allocation_results_to_text(filename, step_count, allocation_time, ...
    total_reward, placement_stats, total_requests, agent_file)
    fid = fopen(filename, 'w');
    fprintf(fid, 'VM Allocation Results (%s)\n', agent_file);
    fprintf(fid, '========================\n\n');
    fprintf(fid, 'Date: %s\n', datestr(now));
    fprintf(fid, 'Agent: %s\n\n', agent_file);
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
    fprintf(fid, 'Total energy consumed: %.2f kWh\n',placement_stats.total_energy);
            fprintf('========================\n\n');
    fclose(fid);
end
