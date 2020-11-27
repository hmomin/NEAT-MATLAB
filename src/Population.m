classdef Population < handle
    %POPULATION is essentially just a recursive group of Genomes.
    %   These Genomes can be compared, sorted, killed off, and mutated in all sorts of
    %   ways. speciesMap contains a mapping from species IDs to their respective species,
    %   where each species is a collection of Genomes. previousMap is just speciesMap from
    %   the previous generation. totalFitness is just the sum total of all fitness values
    %   of every Genome in speciesMap.
    
    properties (Constant)
        % this is delta_t from the original paper by Stanley -> it defines the threshold
        % that compability distances are measured within to determine species
        % compatibility
        COMPATIBILITY_THRESHOLD = 3;
        % probability that a Genome has its weights mutated
        PROB_WEIGHT_MUTATION = 0.8;
        % probability that a Genome undergoes a structural Node mutation
        PROB_NODE_MUTATION = 0.03;
        % probability that a Genome undergoes a structural Connection mutation
        PROB_CONNECTION_MUTATION = 0.05;
        % amount that should be killed off from each individual species
        KILL_OFF_PERCENTAGE = 80;
    end
    
    properties (SetAccess = private)
        speciesMap;
        previousMap;
        totalFitness = 0;
        NUM_INDIVIDUALS;
    end
    
    methods
        function obj = Population(numInputs, numOutputs, numIndividuals, innovTracker)
            %POPULATION constructor expects a number of inputs to train for, a number of
            %outputs to train for, and a preconstructed innovation tracker.
            
            obj.NUM_INDIVIDUALS = numIndividuals;
            % perform type-check for innovation tracker
            if ~isa(innovTracker, 'InnovationTracker')
                error('argument provided to Population() is of type %s, not InnovationTracker', ...
                    class(innovTracker));
            end
            obj.speciesMap = containers.Map('KeyType', 'uint64', 'ValueType', 'any');
            % create individuals with random weights between inputs and outputs
            for k = 1: obj.NUM_INDIVIDUALS
                genome = Genome();
                nodeCounter = 1;
                % start by creating the nodes
                inNodes = [];
                outNodes = [];
                for m = 1: numInputs
                    inNode = Node(nodeCounter, NodeType.INPUT);
                    genome.addNodeGene(inNode);
                    inNodes = [inNodes; inNode];
                    nodeCounter = nodeCounter + 1;
                end
                for n = 1: numOutputs
                    outNode = Node(nodeCounter, NodeType.OUTPUT);
                    genome.addNodeGene(outNode);
                    outNodes = [outNodes; outNode];
                    nodeCounter = nodeCounter + 1;
                end
                % then, create the connections
                for m = 1: length(inNodes)
                    for n = 1: length(outNodes)
                        con = Connection(inNodes(m).id, outNodes(n).id, randn(), true, 0);
                        num = innovTracker.getInnovationNumber(con);
                        con.setInnovationNumber(num);
                        genome.addConnectionGene(con);
                    end
                end
                % figure out what species the individual fits into
                if k == 1
                    obj.speciesMap(1) = genome;
                else
                    vals = values(obj.speciesMap);
                    matchedUp = false;
                    for m = 1: length(vals)
                        testGenome = vals{m}(1);
                        if genome.compatibilityDistance(testGenome) < obj.COMPATIBILITY_THRESHOLD
                            obj.speciesMap(m) = [obj.speciesMap(m); genome];
                            matchedUp = true;
                            break;
                        end
                    end
                    if ~matchedUp
                        obj.speciesMap(length(vals) + 1) = genome;
                    end
                end
                % we'll call this the previous population
                obj.previousMap = containers.Map(obj.speciesMap.keys, obj.speciesMap.values);
            end
        end
        
        function explicitFitnessSharing(obj)
            %EXPLICITFITNESSSHARING performs fitness sharing on the population within
            %individual species.
            %   This should only be called after assigning fitnesses for all Genomes in
            %   the Population. Also, use this as a nice opportunity to compute the total
            %   fitness of the population.
            
            obj.totalFitness = 0;
            map = obj.speciesMap;
            ks = keys(map);
            for k = 1: length(map)
                key = ks{k};
                species = map(key);
                len = length(species);
                for m = 1: len
                    species(m).setFitness(species(m).fitness/len);
                    obj.totalFitness = obj.totalFitness + species(m).fitness;
                end
            end
        end
        
        function reproduce(obj, innovTracker)
            %REPRODUCE creates the next generation of species.
            %   Some Genomes are killed off in each species, per KILL_OFF_PERCENTAGE.
            %   Then, the remaining Genomes are bred and mutated to produce the offspring
            %   for the next generation.
            
            % perform type-check for innovation tracker
            if ~isa(innovTracker, 'InnovationTracker')
                error('argument provided to Population() is of type %s, not InnovationTracker', ...
                    class(innovTracker));
            end
            % set the previous population to the current population
            obj.previousMap = containers.Map(obj.speciesMap.keys, obj.speciesMap.values);
            % create the new population from scratch
            obj.speciesMap = containers.Map('KeyType', 'uint64', 'ValueType', 'any');
            
            % figure out how many organisms should exist in each species based on
            % proportional fitness amount - there may be one less or one more than desired
            % due to roundoff, but treating this as inconsequential
            map = obj.previousMap;
            previousKeys = map.keys;
            previousVals = map.values;
            
            obj.totalFitness = 0;
            bestGenomes = [];
            speciesFitnesses = [];
            for k = 1: length(map)
                key = previousKeys{k};
                % figure out the total fitness of this particular species
                genomes = previousVals{k};
                genomeFitnesses = zeros(length(genomes), 1);
                for m = 1: length(genomes)
                    genomeFitnesses(m) = genomes(m).fitness;
                end
                % find the best
                [~, idx] = max(genomeFitnesses);
                bestGenomes = [bestGenomes; genomes(idx)];
                % kill off genomes below a certain percentage
                abovePercentile = genomeFitnesses >= prctile(genomeFitnesses, obj.KILL_OFF_PERCENTAGE);
                genomeFitnesses = genomeFitnesses(abovePercentile);
                genomes = genomes(abovePercentile);
                speciesFitnesses = [speciesFitnesses; sum(genomeFitnesses)];
                obj.totalFitness = obj.totalFitness + sum(genomeFitnesses);
                map(key) = genomes;
            end
            
            for k = 1: length(previousKeys)
                key = previousKeys{k};
                genomes = map(key);
                
                % figure out the number of organisms allowed for this species (up to
                % roundoff)
                numOrgs = round(speciesFitnesses(k)/obj.totalFitness*obj.NUM_INDIVIDUALS);
            
                % given now how many organisms this species should have, keep some of the
                % best performing individuals and ...
                obj.speciesMap(key) = bestGenomes(k);
                iter = 0;
                while length(obj.speciesMap(key)) < numOrgs && iter < numOrgs
                    % ... perform proportionate selection to create offspring until you
                    % hit the amount of species that you should have
                    parent1 = proportionateSelection(genomes, speciesFitnesses(k));
                    parent2 = proportionateSelection(genomes, speciesFitnesses(k));
                    if parent1.fitness > parent2.fitness
                        child = parent1.crossover(parent2);
                    else
                        child = parent2.crossover(parent1);                        
                    end
                    % perform mutations on the child based on predetermined probabilities
                    if rand() < obj.PROB_WEIGHT_MUTATION
                        child.mutateConnectionWeights();
                    end
                    if rand() < obj.PROB_NODE_MUTATION
                        child.addNodeMutation(innovTracker);
                    end
                    if rand() < obj.PROB_CONNECTION_MUTATION
                        child.addConnectionMutation(innovTracker);
                    end
                    % figure out if the child should be in this species or a different one
                    vals = values(obj.speciesMap);
                    matchedUp = false;
                    for m = 1: length(vals)
                        testGenome = vals{m}(1);
                        if child.compatibilityDistance(testGenome) < obj.COMPATIBILITY_THRESHOLD
                            obj.speciesMap(m) = [obj.speciesMap(m); child];
                            matchedUp = true;
                            break;
                        end
                    end
                    if ~matchedUp
                        newKey = length(vals) + 1;
                        obj.speciesMap(newKey) = child;
                    end
                    iter = iter + 1;
                end
            end
        end
    end
end