classdef InnovationTracker < handle
    %INNOVATIONTRACKER keeps track of all innovations that have happened.
    %   innovations maps innovation numbers to their respective Connection objects.
    
    properties (SetAccess = private)
        innovations;
    end
    
    methods
        function obj = InnovationTracker()
            %INNOVATIONTRACKER constructor.
            %   Instantiates the mapping from innovation number to connection.
            obj.innovations = containers.Map('KeyType', 'uint64', 'ValueType', 'any');
        end
        
        function num = getInnovationNumber(obj, connection)
            %GETINNOVATIONNUMBER retrieves the innovation number given a Connection as
            %input.
            %   Knowledge of the Connection Node IDs is used to determine the innovation
            %   number.
            
            % iterate through the innovations to see if there already exists a connection
            % with this innovation number
            ks = keys(obj.innovations);
            vals = values(obj.innovations);
            innovationExists = false;
            for k = 1: length(obj.innovations)
                con = vals{k};
                if con.inNode == connection.inNode && con.outNode == connection.outNode
                    % then the innovation number already exists -> just return it
                    innovationExists = true;
                    num = ks{k};
                    break;
                end
            end
            % if no innovation number currently exists, create a new one for this unique
            % connection
            if ~innovationExists
                num = uint64(length(obj.innovations) + 1);
                obj.innovations(num) = connection;
            end
        end
    end
end