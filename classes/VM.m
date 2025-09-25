classdef VM < handle
    
    
    properties
        id                  % Unique VM identifier
        cpu_needed          % CPU requirement (fractional units, 0-1)
        memory_needed       % Memory requirement (fractional units, 0-1)  
        hdd_needed          % hdd requirement (fractional units, 0-1)
        ssd_needed          % sdd requirement (fractional units, 0-1)
        start_step          % Step when VM should start
        end_step            % Step when VM should end
        server_id           % Which server it's placed on (0 = not placed)
        is_active           % Whether VM is currently running
        arrival_time        % Original arrival time from trace
    end
    
    methods
        function this = VM(id, cpu, memory, hdd,ssd, start_time, end_time, steps_per_day)
            this.id = id;
            this.cpu_needed = cpu;
            this.memory_needed = memory;
            this.hdd_needed = hdd;
            this.ssd_needed = ssd;
            this.arrival_time = start_time;
            
            % Convert fractional days to step numbers
            this.start_step = max(0, floor(start_time * steps_per_day));
            if isnan(end_time) || end_time < 0
                this.end_step = floor(90 * steps_per_day);  % 90-day cap
            else
                this.end_step = floor(end_time * steps_per_day);
            end
            
            % Ensure minimum duration of 1 step
            if this.end_step <= this.start_step
                this.end_step = this.start_step + 1;
            end
            
            this.server_id = 0;
            this.is_active = false;
        end
        
        function place_on_server(this, server_id)
            this.server_id = server_id;
            this.is_active = true;
        end
        
        function remove_from_server(this)
            this.server_id = 0;
            this.is_active = false;
        end
        
        function should_start = check_should_start(this, current_step)
            should_start = (current_step >= this.start_step) && ~this.is_active;
        end
        
        function should_end = check_should_end(this, current_step)
            should_end = (current_step >= this.end_step) && this.is_active;
        end
        
        function info_str = get_info_string(this)
            info_str = sprintf('VM%d: CPU=%.3f, MEM=%.3f, HDD=%.3f,SSD=%.3f Steps=%d-%d', ...
                this.id, this.cpu_needed, this.memory_needed, this.hdd_needed, ...
                this.ssd_needed, this.start_step, this.end_step);
        end
    end
end
