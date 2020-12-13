classdef Node < matlab.mixin.Copyable
    %NODE is a Node gene that belongs to a particular Genome.
    %   Each Node contains a distinctive ID (id), its NodeType (nType), and its bias.
    %   Input nodes should be given biases of 0.
    
    properties (Constant)
        % the bias can take on values between -MAX_BIAS and +MAX_BIAS
        MAX_BIAS = 100;
    end
    
    properties (SetAccess = private)
        id = -1;
        nType;
        bias;
    end
    
    methods
        function obj = Node(id, nType)
            %NODE constructor expects an integer id and a NodeType.
            
            % perform type-check for NodeType
            if ~isa(nType, 'NodeType')
                error('argument provided to Node() is of type %s, not NodeType Enumeration', ...
                    class(nType));
            else
                obj.nType = nType;
            end
            obj.id = uint64(id);
            % if the node is an input node, it has no bias for consistency purposes
            if obj.nType == NodeType.INPUT
                obj.bias = 0;
            else
                obj.bias = randn();
            end
        end
        
        function perturb(obj)
            %PERTURB perturbs this Node's bias.
            %   A cap is also placed on the bias so that it can't go beyond predetermined
            %   bounds.
            
            obj.bias = obj.bias + randn();
            if obj.bias > obj.MAX_BIAS
                obj.bias = obj.MAX_BIAS;
            elseif obj.bias < -obj.MAX_BIAS
                obj.bias = -obj.MAX_BIAS;
            end
        end
    end
end