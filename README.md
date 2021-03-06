# NEAT-MATLAB

This is an implementation of NeuroEvolution of Augmenting Topologies in MATLAB. There already exists [an implementation in MATLAB written by Christian Mayr](http://nn.cs.utexas.edu/?neatmatlab), so why write another? That implementation was written in 2003, many years before major enhancements to object-oriented programming capabilities were available in MATLAB. As a result, the old implementation is not very tractable. It's worthwhile to reconsider an implementation making full use of classes and specialized data structures, considering MATLAB has come a long way since then.

In writing this implementation, efforts were made to stay as close as possible to [the original paper by Stanley and Miikkulainen](http://nn.cs.utexas.edu/downloads/papers/stanley.ec02.pdf), while maintaining simplicity and readability. All files are thoroughly documented, so you might find it beneficial to dig through them and understand how everything fits together. Also, a script is included that uses NEAT-MATLAB to satisfactorily solve the XOR problem. Feel free to use that script as a starting point for implementing NEAT in your own scripts.

All files in the repository are under the MIT license.
