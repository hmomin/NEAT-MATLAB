classdef Network < handle
    %NETWORK is a Neural Network constructed out of a Genome object.
    %   Network Node objects are stored in arrays segregated by type.
    
    properties (Constant)
        % maximum amount of times that a network can loop in calculation -> used to avoid
        % infinite recursion
        MAX_ITER = 10;
    end
    
    properties (SetAccess = private)
        inputNodes = [];
        outputNodes = [];
        hiddenNodes = [];
        allNodes = [];
    end
    
    methods
        function obj = Network(genome)
            %NETWORK constructor.
            
            % verify type of genome
            if ~isa(genome, 'Genome')
                error('argument provided to Network() is of type %s, not Genome', ...
                    class(genome));
            end
            % create the network structures - first, the nodes
            nodes = genome.nodeGenes.values;
            for k = 1: length(nodes)
                node = nodes{k};
                newNode = NetworkNode(node.id, node.bias);
                if node.nType == NodeType.INPUT
                    obj.inputNodes = [obj.inputNodes; newNode];
                elseif node.nType == NodeType.HIDDEN
                    obj.hiddenNodes = [obj.hiddenNodes; newNode];
                elseif node.nType == NodeType.OUTPUT
                    obj.outputNodes = [obj.outputNodes; newNode];
                else
                    error('incorrect nType of node');
                end
                obj.allNodes = [obj.allNodes; newNode];
            end
            % then, the connections between nodes
            connections = genome.connectionGenes.values;
            for k = 1: length(connections)
                connection = connections{k};
                if connection.enabled
                    outNode = obj.findNode(connection.outNode);
                    inNode = obj.findNode(connection.inNode);
                    outNode.addPrevious(inNode.id, connection.weight);
                end
            end
        end
        
        function resNode = findNode(obj, nodeId)
            %FINDNODE takes as input the integer ID of a Node and retrieves its Network
            %Node handle within the Network.
            %   It simply searches through all of the Nodes until finding the right one.
            
            for k = 1: length(obj.allNodes)
                if obj.allNodes(k).id == nodeId
                    resNode = obj.allNodes(k);
                    return;
                end
            end
        end

        function outputs = feedForward(obj, inputs)
            %FEEDFORWARD computes the outputs of the Network given a set of inputs.
            
            % first, reset all the nodes
            obj.resetNetwork();
            % set the inputs
            for k = 1: length(obj.inputNodes)
                node = obj.inputNodes(k);
                theInput = inputs(k);
                node.setInput(theInput);
                node.setOutputToInput();
            end
            nonInputNodes = [obj.hiddenNodes; obj.outputNodes];
            % loop until the outputs of all Nodes stop changing
            for iter = 1: obj.MAX_ITER
                for k = 1: length(nonInputNodes)
                    node = nonInputNodes(k);
                    node.logPreviousOutput();
                    obj.computeInputSum(node);
                    node.activate();
                end
                if obj.nonInputsStable()
                    break;
                end
            end
            % finally, return the outputs
            outputs = zeros(length(obj.outputNodes), 1);
            for k = 1: length(obj.outputNodes)
                node = obj.outputNodes(k);
                outputs(k) = node.output;
            end
        end
        
        function resetNetwork(obj)
            %RESETNETWORK resets a Network to a state in which all Nodes are back to their
            %starting state.
            
            for k = 1: length(obj.allNodes)
                node = obj.allNodes(k);
                node.reset();
            end
        end
        
        function res = nonInputsStable(obj)
            %NONINPUTSSTABLE returns a logical indicating whether or not the outputs of
            %all non-input Nodes are stable or not.
            %   A Node's output is denoted 'stable' if its current output is the same as
            %   its output in the previous iteration.
            
            nonInputNodes = [obj.hiddenNodes; obj.outputNodes];
            for k = 1: length(nonInputNodes)
                node = nonInputNodes(k);
                if node.output ~= node.previousOutput
                    res = false;
                    return;
                end
            end
            res = true;
        end
        
        function computeInputSum(obj, node)
            %COMPUTEINPUTSUM sets a Node's inputSum to sum(w_i*x_i).
            %   More concretely, for this Node, look at the Nodes feeding values into it:
            %   this Node's inputs. For each input, multiply the relevant weight
            %   connecting it to this Node by the input itself and then add up all of the
            %   results.
            
            % type-check on node
            if ~isa(node, 'NetworkNode')
                error('argument provided to computeInputSum() is of type %s, not NetworkNode', ...
                    class(node));
            end
            node.setInput(0);
            for k = 1: length(node.previous)
                prevId = node.previous(k);
                prevWeight = node.weightsFromPrevious(k);
                curr = obj.findNode(prevId);
                node.setInput(node.inputSum + curr.output*prevWeight);
            end
        end
        
        function print(obj)
            %PRINT displays the nodes, biases, and weights associated with this network in
            %an easily digestable manner.
            %   Useful for debugging.
            
            fprintf('\nBEGIN NETWORK STATS:\n');
            for k = 1: length(obj.allNodes)
                node = obj.allNodes(k);
                fprintf('node %g -> bias: %.10f\n', node.id, node.bias);
                for m = 1: length(node.previous)
                    fprintf('    weight (%g->%g): %.10f\n', ...
                        node.previous(m), node.id, node.weightsFromPrevious(m));
                end
            end
            fprintf('\n');
        end
    end
end