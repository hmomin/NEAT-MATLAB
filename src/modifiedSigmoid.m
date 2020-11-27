function f = modifiedSigmoid(x)
    %MODIFIEDSIGMOID computes a steepened sigmoid of x.
    %   Per the original paper by Stanley, "The steepened sigmoid allows more fine tuning
    %   at extreme activations."
    
    f = 1./(1 + exp(-4.9*x));
end