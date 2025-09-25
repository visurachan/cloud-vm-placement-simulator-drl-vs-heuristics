function agent = create_firstfit_agent(config)
% CREATE_FIRSTFIT_AGENT - Create a First-Fit heuristic agent for VM placement.
    fprintf('Creating First-Fit agent...\n');
    agent = FirstFitAgent(config);
    fprintf('✓ First-Fit agent created successfully!\n');
end
