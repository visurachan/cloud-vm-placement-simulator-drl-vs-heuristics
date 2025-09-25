function run_bestfit_multiple(nRuns)
    % RUN_BESTFIT_MULTIPLE - Execute Best-Fit allocation nRuns times
    rootFolder   = fileparts(mfilename('fullpath'));
    resultsRoot  = fullfile(rootFolder, 'results', 'Best_fit');
    matlabFolder = fullfile(resultsRoot, 'Matlab_format');
    textFolder   = fullfile(resultsRoot, 'Text_format');
    if ~exist(matlabFolder, 'dir'), mkdir(matlabFolder); end
    if ~exist(textFolder,   'dir'), mkdir(textFolder);   end

    if nargin<1, nRuns = 30; end

    % Get a template struct from one run
    template       = run_bestfit_allocation_return();
    allResults     = repmat(template, nRuns, 1);

    % First has already run; store it
    allResults(1) = template;

    % Run the remaining simulations
    for i = 2:nRuns
        fprintf('=== Run %d of %d ===\n', i, nRuns);
        allResults(i) = run_bestfit_allocation_return();
    end

    % Convert to table and reorder columns
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
    matFile = fullfile(matlabFolder, sprintf('bestfit_30runs_%s.mat', ts));
    save(matFile,'T');

    % Save text report
    txtFile = fullfile(textFolder, sprintf('bestfit_30runs_%s.txt', ts));
    fid = fopen(txtFile,'w');
    fprintf(fid, 'Best-Fit Allocation Metrics over %d Runs (generated %s)\n\n', nRuns, datestr(now));
    fclose(fid);
    writetable(T, txtFile, 'FileType','text','Delimiter','\t','WriteMode','append');

    fprintf('✓ MATLAB results saved to: %s\n', matFile);
    fprintf('✓ Text report saved to:   %s\n', txtFile);
end
