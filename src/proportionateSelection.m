function genome = proportionateSelection(genomeList, totalFitness)
    %PROPORTIONATESELECTION chooses a Genome using fitness-proportionate selection from
    %genomeList.
    %   Genomes with higher fitness values are more likely to be picked probabilistically.
    
    % type-check on genomeList
    if ~isa(genomeList, 'Genome')
        error('argument provided to proportionateSelection() is of type %s, not Genome', ...
            class(genomeList));
    end
    pick = rand()*totalFitness;
    runningTotal = 0;
    for k = 1: length(genomeList)
        runningTotal = runningTotal + genomeList(k).fitness;
        if runningTotal > pick
            genome = genomeList(k);
            return;
        end
    end
end