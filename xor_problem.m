% this script implements NEAT to solve the XOR problem
clc; clear; close all;

DESIRED_FITNESS = 10^6;
MAX_ITERATIONS = 10000;
% a higher error power penalizes individual errors at the expense of the collective error.
% an error power of 2 implements the usual square-distance cost function, but converges at
% a much slower rate.
ERROR_POWER = 4;

% initialize variables
fitness = 0;
populationFitnesses = zeros(MAX_ITERATIONS, 1);
tracker = InnovationTracker();
pop = Population(2, 1, 150, tracker);
inputPattern = [
    0, 0;
    0, 1;
    1, 0;
    1, 1
];
outputPattern = [
    0;
    1;
    1;
    0;
];

for k = 1: MAX_ITERATIONS
    beginTime = tic;
    speciesMap = pop.speciesMap;
    genomes = speciesMap.values;
    fullFitnesses = [];
    
    for p = 1: length(genomes)
        genomeSubset = genomes{p};
        fitnesses = zeros(length(genomeSubset), 1);
        
        % create a network for each genome and evaluate its fitness
        for m = 1: length(genomeSubset)
            net = Network(genomeSubset(m));
            % determine the fitness based off of the input pattern
            fitness = 0;
            outputs = zeros(size(inputPattern, 1), 1);
            
            for n = 1: size(inputPattern, 1)
                inputs = inputPattern(n, :);
                output = net.feedForward(inputs);
                outputs(n) = output;
                % want to minimize the difference between output and expected output
                absDist = abs(output - outputPattern(n));
                fitness = fitness + absDist^ERROR_POWER;
            end
            
            fitness = 1/fitness;
            if fitness > DESIRED_FITNESS
                break;
            end
            genomeSubset(m).setFitness(fitness);
            fitnesses(m) = fitness;
        end
        
        if fitness > DESIRED_FITNESS
            break;
        end
        fullFitnesses = [fullFitnesses; fitnesses];
    end
    
    if fitness > DESIRED_FITNESS
        break;
    end
    pop.explicitFitnessSharing();
    pop.reproduce(tracker);
    fitness = mean(fullFitnesses);
    populationFitnesses(k) = fitness;
    fprintf('generation %g - time taken: %.2fs - num species: %g - mean fitness: %.2f\n', ...
        k, toc(beginTime), length(genomes), fitness);
end

figure(1);
hold on;
plot(populationFitnesses(populationFitnesses > 0));
xlabel('generation number');
ylabel('mean fitness');
set(gca, 'FontSize', 18);
hold off;
outputs
return;