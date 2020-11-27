classdef Connection < matlab.mixin.Copyable
    %CONNECTION is a connection gene that belongs to a particular genome.
    %   Each Connection contains the id of the input node (inNode), the id of the output
    %   node (outNode), the weight of the connection (weight), whether or not it's enabled
    %   (enabled), and the number of the innovation that this connection represents
    %   (numInnovation).
    
    properties (Constant)
        % the weight can take on values between -MAX_WEIGHT and +MAX_WEIGHT
        MAX_WEIGHT = 100000;
    end
    
    properties (SetAccess = private)
        inNode;
        outNode;
        weight;
        enabled;
        numInnovation;
    end
    
    methods
        function obj = Connection(inNode, outNode, weight, enabled, numInnovation)
            %CONNECTION constructor.
            %   Relevant types are forced on respective inputs.
            obj.inNode = uint64(inNode);
            obj.outNode = uint64(outNode);
            obj.weight = double(weight);
            obj.enabled = logical(enabled);
            obj.numInnovation = uint64(numInnovation);
        end
        
        function disable(obj)
            %DISABLE disables this connection gene.
            obj.enabled = false;
        end
        
        function enable(obj)
            %ENABLE enables this connection gene.
            obj.enabled = true;
        end
        
        function perturb(obj)
            %PERTURB perturbs this connection's weight.
            %   A cap is also placed on the weight so that it can't go beyond
            %   predetermined bounds.
            obj.weight = obj.weight + randn();
            if obj.weight > obj.MAX_WEIGHT
                obj.weight = obj.MAX_WEIGHT;
            elseif obj.weight < -obj.MAX_WEIGHT
                obj.weight = -obj.MAX_WEIGHT;
            end
        end
        
        function setInnovationNumber(obj, num)
            %SETINNOVATIONNUMBER sets the innovation number of this connection.
            %   It provides the ability to change a connection's innovation number once
            %   other connection IDs have been cross-checked.
            obj.numInnovation = num;
        end
    end
end