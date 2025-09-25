% add all folders to MATLAB path
% Run this first to ensure all components can find each other

fprintf('Setting up DQN VM Allocation System...\n');

% Get the current directory (root of project)
root_dir = pwd;

% Add all subfolders to MATLAB path
addpath(genpath(root_dir));

fprintf('✓ All folders added to MATLAB path\n');

% Verify all required files exist
required_files = {
    'agents/create_dqn_agent.m',
    'classes/VM.m', 
    'config/thermal_dqn_config.m',
    'environments/VMEnvironment.m',
    'utils/load_vm_traces.m',
    'data/train.csv'
};

fprintf('\nChecking required files:\n');
all_found = true;
for i = 1:length(required_files)
    if exist(required_files{i}, 'file')
        fprintf('✓ %s\n', required_files{i});
    else
        fprintf('✗ %s - NOT FOUND\n', required_files{i});
        all_found = false;
    end
end

if all_found
    fprintf('\n✓ All required files found!\n');
    fprintf('\nNext steps:\n');
    fprintf('1. Run: test_integration()     - Test all components\n');
    fprintf('2. Run: train_dqn_vm_allocator() - Train the agent\n');
    fprintf('3. Run: run_vm_allocation()    - Deploy trained agent\n');
else
    fprintf('\n⚠ Some files are missing. Please check your project structure.\n');
end

fprintf('\nSystem setup complete!\n');