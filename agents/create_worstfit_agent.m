function agent = create_worstfit_agent(config)
% CREATE_WORSTFIT_AGENT - Create a Worst-Fit heuristic agent for VM placement.
    fprintf('Creating Worst-Fit agent...\n');
    agent = WorstFitAgent(config);
    fprintf('✓ Worst-Fit agent created successfully!\n');
end
