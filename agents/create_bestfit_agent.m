function agent = create_bestfit_agent(config)
% CREATE_BESTFIT_AGENT - Create a Best-Fit heuristic agent for VM placement.
    fprintf('Creating Best-Fit agent...\n');
    agent = BestFitAgent(config);
    fprintf('✓ Best-Fit agent created successfully!\n');
end
