function run_worstfit_multiple(nRuns)
    % RUN_WORSTFIT_MULTIPLE - Execute Worst-Fit allocation nRuns times

    rootFolder   = fileparts(mfilename('fullpath'));
    resultsRoot  = fullfile(rootFolder, 'results', 'Worst_Fit');
    matlabFolder = fullfile(resultsRoot, 'Matlab_format');
    textFolder   = fullfile(resultsRoot, 'Text_format');
    if ~exist(matlabFolder, 'dir'), mkdir(matlabFolder); end
    if ~exist(textFolder,   'dir'), mkdir(textFolder);   end

    if nargin<1, nRuns = 30; end

    % Template for consistent struct array size
    template = run_worstfit_allocation_return();
    allResults = repmat(template, nRuns, 1);
    allResults(1) = template;

    for i = 2:nRuns
        fprintf('=== Run %d of %d ===\n', i, nRuns);
        allResults(i) = run_worstfit_allocation_return();
    end

    % Convert to table, add Run column, reorder columns
    T = struct2table(allResults);
    T.Run = (1:nRuns)';
    T = movevars(T, 'Run', 'Before', 1);
    T = T(:, {'Run','step_count','allocation_time_sec',...
              'avg_time_per_step_ms','avg_time_per_vm_ms',...
              'total_reward','total_requests',...
              'successful_placements','rejected_placements',...
              'success_rate_pct','rejection_rate_pct',...
              'total_energy_kWh'});

    % Save .mat
    ts      = datestr(now,'yyyy-mm-dd_HH-MM-SS');
    matFile = fullfile(matlabFolder, sprintf('worstfit_30runs_%s.mat', ts));
    save(matFile,'T');

    % Save text report
    txtFile = fullfile(textFolder, sprintf('worstfit_30runs_%s.txt', ts));
    fid = fopen(txtFile,'w');
    fprintf(fid, 'Worst-Fit Allocation Metrics over %d Runs (generated %s)\n\n', nRuns, datestr(now));
    fclose(fid);
    writetable(T, txtFile, 'FileType','text','Delimiter','\t','WriteMode','append');

    fprintf('✓ MATLAB results saved to: %s\n', matFile);
    fprintf('✓ Text report saved to:   %s\n', txtFile);
end
