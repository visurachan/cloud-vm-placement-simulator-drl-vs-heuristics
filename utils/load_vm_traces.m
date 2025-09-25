function [vm_list, trace_stats] = load_vm_traces(config)
    % LOAD_VM_TRACES - Load and process VM traces for simulation
    
    fprintf('Loading VM traces from: %s\n', config.trace_file);
    
    if ~exist(config.trace_file, 'file')
        error('Trace file not found: %s', config.trace_file);
    end
    
    %% Load raw trace data
    try
        data = readtable(config.trace_file);
        fprintf('✓ Loaded %d raw VM records\n', height(data));
    catch ME
        error('Failed to load trace file: %s', ME.message);
    end
    
    %% Validate required columns
    required_cols = {'id', 'cpu', 'memory', 'hdd','ssd', 'start_time', 'end_time'};
    missing_cols = setdiff(required_cols, data.Properties.VariableNames);
    if ~isempty(missing_cols)
        error('Missing required columns: %s', strjoin(missing_cols, ', '));
    end
    
    %% Filter and downsample
    % Remove invalid entries
    valid_idx = data.cpu > 0 & data.memory > 0 & data.hdd >= 0 & data.ssd >= 0 & data.start_time > 0;
    data = data(valid_idx, :);
    
    
    % Downsample if requested not exactly 10% more randomized
    if config.trace_downsample_rate < 1.0
        keep_idx = rand(height(data), 1) < config.trace_downsample_rate;
        data = data(keep_idx, :);
    end
    
    % Sort by start time
    data = sortrows(data, 'start_time');
    
    %% Convert to VM objects
    num_vms = height(data);
    vm_list = VM.empty(num_vms, 0);
    
    for i = 1:num_vms
        end_time = data.end_time(i);
        if isempty(end_time) || (ischar(end_time) && strcmp(end_time, 'NULL'))
            end_time = NaN;
        end
        
        vm_list(i) = VM(data.id(i), data.cpu(i), data.memory(i), data.hdd(i), ...
                       data.ssd(i), data.start_time(i), end_time, config.steps_per_day);
    end
    
    %% Calculate statistics
    trace_stats = struct();
    trace_stats.total_vms = num_vms;
    trace_stats.avg_cpu = mean(data.cpu);
    trace_stats.avg_memory = mean(data.memory);
    trace_stats.avg_hdd = mean(data.hdd);
    trace_stats.avg_ssd = mean(data.ssd);
    
    fprintf('✓ VM traces loaded successfully: %d VMs\n', num_vms);
end
