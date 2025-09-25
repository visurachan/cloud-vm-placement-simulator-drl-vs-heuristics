function run_DQN_multiple(nRuns)
    % RUN_DQN_MULTIPLE - Execute DQN allocation nRuns times

    rootFolder   = fileparts(mfilename('fullpath'));
    resultsRoot  = fullfile(rootFolder, 'results', 'DQN');
    matlabFolder = fullfile(resultsRoot, 'Matlab_format');
    textFolder   = fullfile(resultsRoot, 'Text_format');
    if ~exist(matlabFolder, 'dir'), mkdir(matlabFolder); end
    if ~exist(textFolder,   'dir'), mkdir(textFolder);   end

    if nargin<1, nRuns = 30; end

    % Template struct
    [template, agent_file] = run_DQN_allocation_return();
    allResults = repmat(template, nRuns, 1);
    agentFiles = strings(nRuns, 1);
    allResults(1) = template;
    agentFiles(1) = agent_file;

    for i = 2:nRuns
        fprintf('=== Run %d of %d ===\n', i, nRuns);
        [allResults(i), agentFiles(i)] = run_DQN_allocation_return();
    end

    % Convert to table, add Run and agent_file columns
    T = struct2table(allResults);
    T.Run = (1:nRuns)';
    if ~ismember('agent_file', T.Properties.VariableNames)
        T.agent_file = agentFiles;
    end
    T = movevars(T, 'Run', 'Before', 1);
    T = movevars(T, 'agent_file', 'After', 'Run');
    T = T(:, {'Run','agent_file','step_count','allocation_time_sec',...
              'avg_time_per_step_ms','avg_time_per_vm_ms',...
              'total_reward','total_requests',...
              'successful_placements','rejected_placements',...
              'success_rate_pct','rejection_rate_pct',...
              'total_energy_kWh'});

    % Save .mat
    ts      = datestr(now,'yyyy-mm-dd_HH-MM-SS');
    matFile = fullfile(matlabFolder, sprintf('DQN_30runs_%s.mat', ts));
    save(matFile,'T');

    % Save text report
    txtFile = fullfile(textFolder, sprintf('DQN_30runs_%s.txt', ts));
    fid = fopen(txtFile,'w');
    fprintf(fid, 'DQN Allocation Metrics over %d Runs (generated %s)\n\n', nRuns, datestr(now));
    fclose(fid);
    writetable(T, txtFile, 'FileType','text','Delimiter','\t','WriteMode','append');

    fprintf('✓ MATLAB results saved to: %s\n', matFile);
    fprintf('✓ Text report saved to:   %s\n', txtFile);
end
