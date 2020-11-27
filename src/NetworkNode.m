classdef NetworkNode < handle
    %NETWORKNODE is a node associated with some Neural Network.
    %   Each NetworkNode holds the id associated with the same Node gene from a Genome.
    %   Although unspecified in the original paper by Stanley, each non-input NetworkNode
    %   is allowed a bias as well, such that
    %   output = modified_sigmoid(sum(w_i*x_i) + bias).
    %   previous is a list of the Node IDs that feed into this one and respective weights
    %   are held in weightsFromPrevious. inputSum is sum(w_i*x_i) for each of these
    %   previous Nodes. previousOutput is used to check for stability or divergence.
    %   isOutput simply denotes whether or not this Node is an output.
    
    properties (SetAccess = private)
        id;
        bias;
        previous = [];
        weightsFromPrevious = [];
        inputSum = 0;
        output = 0;
        previousOutput = 0;
        isOutput = false;
    end
    
    methods
        function obj = NetworkNode(id, bias)
            %NETWORKNODE constructor expects an ID for this node as well as an initial
            %bias.
            obj.id = id;
            obj.bias = bias;
        end
        
        function addPrevious(obj, prevId, weight)
            %ADDPREVIOUS adds a new previous node to this Node's lists in the form of an
            %ID and a weight.
            obj.previous = [obj.previous; prevId];
            obj.weightsFromPrevious = [obj.weightsFromPrevious; weight];
        end
        
        function reset(obj)
            %RESET resets the inputs and outputs of this NetworkNode.
            obj.inputSum = 0;
            obj.output = 0;
            obj.previousOutput = 0;
        end
                
        function setInput(obj, num)
            %SETINPUT sets the inputSum of this NetworkNode.
            obj.inputSum = num;
        end
        
        function setOutputToInput(obj)
            %SETOUTPUTTOINPUT is used for input nodes, whose outputs should be the same as
            %their inputs -> no sigmoid business here.
            obj.output = obj.inputSum;
        end
        
        function logPreviousOutput(obj)
            %LOGPREVIOUSOUTPUT logs the current output within the previous output
            %variable.
            obj.previousOutput = obj.output;
        end
        
        function activate(obj)
            %ACTIVATE applies the relevant activation function to this NetworkNode's
            %inputs and biases.
            obj.output = modifiedSigmoid(obj.inputSum + obj.bias);
        end
    end
end