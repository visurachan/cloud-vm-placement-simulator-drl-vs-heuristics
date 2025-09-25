function test_integration()
    % TEST_INTEGRATION - Quick integration test for all components
    
    fprintf('=== Testing DQN VM Allocation System Integration ===\n\n');
    
    %% Step 1: Test Configuration
    fprintf('1. Testing Configuration...\n');
    try
        config = thermal_dqn_config();
        fprintf('   ✓ Config loaded: %d servers, state size %d\n', ...
                config.num_servers, config.state_size);
    catch ME
        fprintf('   ✗ Config failed: %s\n', ME.message);
        return;
    end
    
    %% Step 2: Test Data Loading
    fprintf('\n2. Testing Data Loading...\n');
    try
        if exist(config.trace_file, 'file')
            [vm_list, stats] = load_vm_traces(config);
            fprintf('   ✓ Loaded %d VMs from traces\n', length(vm_list));
        else
            fprintf('   ⚠ No trace file found - will use random VMs\n');
        end
    catch ME
        fprintf('   ✗ Data loading failed: %s\n', ME.message);
    end
    
    %% Step 3: Test Environment
    fprintf('\n3. Testing Environment...\n');
    try
        env = VMEnvironment(config);
        obs = reset(env);
        fprintf('   ✓ Environment created, observation size: %d\n', length(obs));
        
        % Test one step
        action = randi(config.num_actions) - 1;
        [new_obs, reward, done] = step(env, action);
        fprintf('   ✓ Environment step works, reward: %.2f\n', reward);
    catch ME
        fprintf('   ✗ Environment failed: %s\n', ME.message);
        return;
    end
    
    %% Step 4: Test Agent
    fprintf('\n4. Testing DQN Agent...\n');
    try
        agent = create_dqn_agent(config);
        % After you call reset(env) or step(env,...), before passing to getAction:
        obs = reset(env);
        action = getAction(agent, obs);
        if iscell(action)
            action = action{1};  % Extract from cell array
        
        end
        fprintf('   ✓ Agent created and can select actions: %d\n', action);
    catch ME
        fprintf('   ✗ Agent failed: %s\n', ME.message);
        return;
    end
    
    %% Step 5: Test Agent-Environment Interaction
    fprintf('\n5. Testing Agent-Environment Integration...\n');
    try
        obs = reset(env);
        for i = 1:5
            action = getAction(agent, obs);
            if iscell(action)
            action = action{1};  % Extract from cell array
        
            end
            [obs, reward, done] = step(env, action);
            fprintf('   Step %d: Action=%d, Reward=%.2f\n', i, action, reward);
            if done
                obs = reset(env);
            end
        end
        fprintf('   ✓ Agent-Environment integration works!\n');
    catch ME
        fprintf('   ✗ Integration failed: %s\n', ME.message);
        return;
    end
    
    fprintf('\n✓ ALL TESTS PASSED - System is ready for training!\n');
end