function agent = create_dqn_agent(config)
    % CREATE_DQN_AGENT - Creates a DQN agent for VM placement
    
    fprintf('Creating DQN agent...\n');
    
    %% Define Network Architecture
    state_dim = config.state_size;
    num_actions = config.num_actions;
    

    
    fprintf('- State dimension: %d\n', state_dim);
    fprintf('- Number of actions: %d\n', num_actions);
    
    %% Create Neural Network Layers
    layers = [
        featureInputLayer(state_dim, 'Normalization', 'none', 'Name', 'state') %specifying not to normalize since its already normalized
                                                                               % name of the layer is state
        fullyConnectedLayer(256, 'Name', 'fc1')
        reluLayer('Name', 'relu1')
        fullyConnectedLayer(128, 'Name', 'fc2')
        reluLayer('Name', 'relu2')
        fullyConnectedLayer(64, 'Name', 'fc3')
        reluLayer('Name', 'relu3')
        fullyConnectedLayer(num_actions, 'Name', 'output')
    ];
    
    %% Create Network
    net = dlnetwork(layers, Initialize=true); %set to true when ready to train
    
    %% Define Specifications
    obsInfo = rlNumericSpec([state_dim 1], ...
        'LowerLimit', zeros(state_dim, 1), ...
        'UpperLimit', ones(state_dim, 1));
    
    actInfo = rlFiniteSetSpec(0:(num_actions-1));
    
    %% Create Q-Value Function
    critic = rlVectorQValueFunction(net, obsInfo, actInfo);
    
    %% Configure and Create Agent
    agentOpts = rlDQNAgentOptions(...
        'SampleTime', 1, ...
        'DiscountFactor', 0.99, ...
        'ExperienceBufferLength', 10000, ...
        'MiniBatchSize', 64, ...
        'TargetUpdateFrequency', 100);
      
    
    agentOpts.EpsilonGreedyExploration.EpsilonMin = 0.01;
    agentOpts.EpsilonGreedyExploration.EpsilonDecay = 0.995;
    
    agent = rlDQNAgent(critic,agentOpts);
    
    fprintf('✓ DQN agent created successfully!\n');
end
