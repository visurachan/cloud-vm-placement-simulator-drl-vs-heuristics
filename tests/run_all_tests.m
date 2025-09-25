function run_all_tests()
    % RUN_ALL_TESTS - Execute all test scripts in sequence
    
    fprintf(' Starting All Tests...\n\n');
    
    % Setup paths - go up one level since we're in tests/ folder
    addpath('../config/');
    addpath('../classes/');
    addpath('../utils/');
    addpath('../agents/');
    addpath('../environments/');
    addpath('./');  % Current directory (tests)
    addpath('../data');
    
    test_results = [];
    
    %% Test 1: Configuration
    fprintf('=== TEST 1: Configuration ===\n');
    try
        config = thermal_dqn_config();
        assert(config.num_servers == 120, 'Server count incorrect');
        assert(config.state_size > 0, 'State size invalid');
        fprintf('✅ Configuration test PASSED\n\n');
        test_results(1) = true;
    catch ME
        fprintf('❌ Configuration test FAILED: %s\n\n', ME.message);
        test_results(1) = false;
    end
    
    %% Test 2: VM Class
    fprintf('=== TEST 2: VM Class ===\n');
    try
        vm = VM(1, 0.25, 0.5, 0.3, 0.5, 1.2, 288);
        assert(vm.start_step == 144, 'Start step calculation failed');
        assert(vm.end_step == 345, 'End step calculation failed');
        vm.place_on_server(5);
        assert(vm.server_id == 5 && vm.is_active, 'VM placement failed');
        fprintf('✅ VM class test PASSED\n\n');
        test_results(2) = true;
    catch ME
        fprintf('❌ VM class test FAILED: %s\n\n', ME.message);
        test_results(2) = false;
    end
    
    %% Test 3: Trace Loading
    fprintf('=== TEST 3: Trace Loading ===\n');
    try
        create_sample_traces();
        config = thermal_dqn_config();
        [vm_list, stats] = load_vm_traces(config);
        assert(~isempty(vm_list), 'No VMs loaded');
        assert(isa(vm_list(1), 'VM'), 'VM objects not created');
        fprintf('✅ Trace loading test PASSED\n\n');
        test_results(3) = true;
    catch ME
        fprintf('❌ Trace loading test FAILED: %s\n\n', ME.message);
        test_results(3) = false;
    end
    
    %% Test 4: Environment
    fprintf('=== TEST 4: Environment ===\n');
    try
        config = thermal_dqn_config();
        env = VMEnvironment(config);
        obs = reset(env);
        assert(length(obs) == config.state_size, 'Observation size wrong');
        [obs, reward, done, ~] = step(env, 1);
        assert(isscalar(reward), 'Reward not scalar');
        fprintf('✅ Environment test PASSED\n\n');
        test_results(4) = true;
    catch ME
        fprintf('❌ Environment test FAILED: %s\n\n', ME.message);
        test_results(4) = false;
    end
    
    %% Test 5: Full Integration
    fprintf('=== TEST 5: Full Integration ===\n');
    try
        config = thermal_dqn_config();
        env = VMEnvironment(config);
        agent = create_dqn_agent(config);
        
        obs = reset(env);
        action = getAction(agent, obs);
        if iscell(action), action = action{1}; end
        [obs, reward, ~, ~] = step(env, action);
        
        fprintf('✅ Integration test PASSED\n\n');
        test_results(5) = true;
    catch ME
        fprintf('❌ Integration test FAILED: %s\n\n', ME.message);
        test_results(5) = false;
    end
    
    %% Summary
    fprintf('TEST SUMMARY \n');
    test_names = {'Configuration', 'VM Class', 'Trace Loading', 'Environment', 'Integration'};
    for i = 1:length(test_results)
        status = test_results(i);
        if status
            fprintf('  ✅ %s\n', test_names{i});
        else
            fprintf('  ❌ %s\n', test_names{i});
        end
    end
    
    pass_rate = sum(test_results) / length(test_results) * 100;
    fprintf('\n Pass Rate: %.0f%% (%d/%d tests passed)\n', pass_rate, sum(test_results), length(test_results));
    
    if all(test_results)
        fprintf(' ALL TESTS PASSED! Ready for training!\n');
    else
        fprintf(' Some tests failed. Fix issues before training.\n');
    end
end
