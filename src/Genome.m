classdef Genome < matlab.mixin.Copyable
    %GENOME is a member of a population that can be immediately translated into a Neural
    %Network.
    %   connectionGenes is a mapping of this Genome's Connections by innovation number.
    %   nodeGenes is a mapping of this Genome's Nodes by their IDs. The fitness of this
    %   Genome can also be set via setFitness() to allow for Population reproduction and
    %   mutation that favors elite performers.
    
    % hyperparameters
    properties (Constant)
        % probability that a Connection is perturbed
        PROB_PERTURB = 0.9;
        % probability that a disabled Connection becomes enabled
        PROB_ENABLE = 0.25;
        % the paper uses {c1, c2, c3}, but disjoint and excess genes are functionally
        % treated as the same in this implementation, so there's no need for c2
        C1 = 1;
        C3 = 0.4;
        % maximum amount of iterations before we give up looking for a Connection
        MAX_CONNECTION_ITER = 10;
        % half-range of new Connection weight
        NEW_WEIGHT_HALF_RANGE = 10;
    end
    
    properties (SetAccess = private)
        connectionGenes;
        nodeGenes;
        fitness = 0;
    end
    
    methods
        function obj = Genome()
            %GENOME constructor.
            %   Instantiates the maps for Connections and Nodes.
            obj.connectionGenes = containers.Map('KeyType', 'uint64', 'ValueType', 'any');
            obj.nodeGenes = containers.Map('KeyType', 'uint64', 'ValueType', 'any');
        end
        
        function setFitness(obj, num)
            %SETFITNESS sets the fitness of this Genome.
            obj.fitness = num;
        end
        
        function addConnectionGene(obj, gene)
            %ADDCONNECTIONGENE adds a Connection object to the connectionGenes map of this
            %Genome.
            
            % perform type-check on gene
            if ~isa(gene, 'Connection')
                error('argument provided to addConnectionGene() is of type %s, not Connection', ...
                    class(gene));
            end
            obj.connectionGenes(gene.numInnovation) = gene;
        end
        
        function addNodeGene(obj, gene)
            %ADDNODEGENE adds a Node object to the nodeGenes map of this Genome.
            
            % perform type-check on gene
            if ~isa(gene, 'Node')
                error('argument provided to addNodeGene() is of type %s, not Node', ...
                    class(gene));
            end
            obj.nodeGenes(gene.id) = gene;
        end
        
        function mutateConnectionWeights(obj)
            %MUTATECONNECTIONWEIGHTS mutates the weights of Connections in connectionGenes
            %and the biases in each non-input Node.
            
            % mutate the weights
            vals = values(obj.connectionGenes);
            for k = 1: length(obj.connectionGenes)
                if rand() < obj.PROB_PERTURB
                    vals{k}.perturb();
                end
            end
            % mutate the biases of each non-input node
            nodes = values(obj.nodeGenes);
            for k = 1: length(obj.nodeGenes)
                if nodes{k}.nType ~= NodeType.INPUT && rand() < obj.PROB_PERTURB
                    nodes{k}.perturb();
                end
            end
        end
        
        function addConnectionMutation(obj, innovTracker)
            %ADDCONNECTIONMUTATION structurally mutates a Genome by adding a Connection.
            %   This method creates a single new Connection gene with a randomized weight
            %   between two previously unconnected Nodes.
            
            % perform type-check on innovTracker
            if ~isa(innovTracker, 'InnovationTracker')
                error('argument provided to addNodeMutation() is of type %s, not InnovationTracker', ...
                    class(innovTracker));
            end
            
            connections = values(obj.connectionGenes);
            nodeIds = keys(obj.nodeGenes);
            uniqueConnectionFound = false;
            iter = 0;
            while ~uniqueConnectionFound && iter < obj.MAX_CONNECTION_ITER
                id1 = nodeIds{randi(numel(nodeIds))};
                id2 = id1;
                while id2 == id1
                    id2 = nodeIds{randi(numel(nodeIds))};
                end
                if obj.nodeGenes(id2).nType == NodeType.INPUT
                    break;
                end
                uniqueConnectionFound = true;
                for k = 1: length(connections)
                    con = connections{k};
                    if con.inNode == id1 && con.outNode == id2
                        uniqueConnectionFound = false;
                    end
                end
                iter = iter + 1;
            end
            if uniqueConnectionFound
                % we've now confirmed that we don't have a Connection between id1 and id2.
                % create a new Connection between these Nodes with a new innovation
                % number. cross-check innovation numbers with the global innovation
                % tracker.
                newCon = Connection(id1, id2, obj.NEW_WEIGHT_HALF_RANGE*(2*rand() - 1), true, 0);
                innovNum = innovTracker.getInnovationNumber(newCon);
                newCon.setInnovationNumber(innovNum);
                obj.connectionGenes(innovNum) = newCon;
            end
        end
        
        function addNodeMutation(obj, innovTracker)
            %ADDNODEMUTATION structurally mutates a Genome by adding a Node in the middle
            %of a Connection, splitting it into two separate Connections.
            %   The weight of the "in-connection" becomes 1 while the weight of the
            %   "out-connection" becomes the weight of the original Connection before it
            %   was split.
            
            % perform type-check on innovTracker
            if ~isa(innovTracker, 'InnovationTracker')
                error('argument provided to addNodeMutation() is of type %s, not InnovationTracker', ...
                    class(innovTracker));
            end
            % choose a random connection
            connections = values(obj.connectionGenes);
            con = connections{randi(numel(connections))};
            
            % disable the old connection
            con.disable();
            
            % create a new node in the list
            newNode = Node(length(obj.nodeGenes) + 1, NodeType.HIDDEN);
            obj.nodeGenes(newNode.id) = newNode;
            
            % cross-check innovation numbers with global innovation tracker
            inConnection = Connection(con.inNode, newNode.id, 1, true, 0);
            innovNum = innovTracker.getInnovationNumber(inConnection);
            inConnection.setInnovationNumber(innovNum);
            obj.connectionGenes(inConnection.numInnovation) = inConnection;
            
            outConnection = Connection(newNode.id, con.outNode, con.weight, true, 0);
            innovNum = innovTracker.getInnovationNumber(outConnection);
            outConnection.setInnovationNumber(innovNum);
            obj.connectionGenes(outConnection.numInnovation) = outConnection;
        end
        
        function offspring = crossover(p1, p2)
            %CROSSOVER creates a child from two parent Genomes, p1 and p2.
            %   It is assumed that the first parent is at least fitter than the second,
            %   i.e. child = crossover(p1, p2) assumes p1.fitness >= p2.fitness.
            
            % perform type-check on genome
            if ~isa(p2, 'Genome')
                error('argument provided to crossover() is of type %s, not Genome', ...
                    class(p2));
            end
            % require that the fitness of p1 is at least as much as p2
            if p1.fitness < p2.fitness
                error('with p1.crossover(p2), require p1.fitness >= p2.fitness');
            end
            offspring = Genome();
            % figure out which genes match up
            p1InnovNums = keys(p1.connectionGenes);
            p2InnovNums = keys(p2.connectionGenes);
            p1InnovList = cell2mat(p1InnovNums);
            p2InnovList = cell2mat(p2InnovNums);
            matchingGenes = intersect(p1InnovList, p2InnovList);
            % since p1 is fitter than p2, we only care about setdiff from p1
            p1Diff = setdiff(p1InnovList, p2InnovList);
            % parse through the matching genes and select randomly between each parent
            for k = 1: length(matchingGenes)
                matchingNum = matchingGenes(k);
                % flip a coin to decide which parent to go with
                if rand() < 0.5
                    chosenParent = p1;
                else
                    chosenParent = p2;
                end
                newGene = copy(chosenParent.connectionGenes(matchingNum));
                % enable if disabled via a preset chance
                if ~newGene.enabled && rand() < p1.PROB_ENABLE
                    newGene.enable();
                end
                offspring.addConnectionGene(newGene);
                % add the corresponding nodes too
                newInNode = copy(chosenParent.nodeGenes(newGene.inNode));
                newOutNode = copy(chosenParent.nodeGenes(newGene.outNode));
                offspring.addNodeGene(newInNode);
                offspring.addNodeGene(newOutNode);
            end
            % now go through the disparate genes and add them in for the fit parent
            for k = 1: length(p1Diff)
                innovNum = p1Diff(k);
                newGene = copy(p1.connectionGenes(innovNum));
                % enable if disabled via a preset chance
                if ~newGene.enabled && rand() < p1.PROB_ENABLE
                    newGene.enable();
                end
                offspring.addConnectionGene(newGene);
                % add the corresponding nodes too
                newInNode = copy(p1.nodeGenes(newGene.inNode));
                newOutNode = copy(p1.nodeGenes(newGene.outNode));
                offspring.addNodeGene(newInNode);
                offspring.addNodeGene(newOutNode);
            end
        end
        
        function delta = compatibilityDistance(g1, g2)
            %COMPATIBILITYDISTANCE computes the compatibility distance, delta, between two
            %Genomes.
            %   This is used for speciation via a threshold
            %   (Population.COMPATIBILITY_THRESHOLD).
            
            % perform type-check on genome
            if ~isa(g2, 'Genome')
                error('argument provided to compatibilityDistance() is of type %s, not Genome', ...
                    class(g2));
            end
            % figure out which genes match up and which don't
            g1InnovNums = keys(g1.connectionGenes);
            g2InnovNums = keys(g2.connectionGenes);
            g1InnovList = cell2mat(g1InnovNums);
            g2InnovList = cell2mat(g2InnovNums);
            matchingGenes = intersect(g1InnovList, g2InnovList);
            numExtra = length(setdiff(g1InnovList, g2InnovList)) + length(setdiff(g2InnovList, g1InnovList));
            N = max([length(g1.connectionGenes), length(g2.connectionGenes)]);
            % now, we just need the average weight differences of matching genes
            avgWeightDiffs = 0;
            for k = 1: length(matchingGenes)
                num = matchingGenes(k);
                g1Gene = g1.connectionGenes(num);
                g2Gene = g2.connectionGenes(num);
                % taking the absolute value of the weight difference, since the absolute
                % value doesn't depend on the order of parents
                avgWeightDiffs = avgWeightDiffs + abs(g1Gene.weight - g2Gene.weight);
            end
            avgWeightDiffs = avgWeightDiffs/length(matchingGenes);
            % now that we have all the pieces, we can calculate delta
            delta = g1.C1*numExtra/N + g1.C3*avgWeightDiffs;
        end
    end
end