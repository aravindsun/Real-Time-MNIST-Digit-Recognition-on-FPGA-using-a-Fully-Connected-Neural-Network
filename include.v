`define pretrained
`define numLayers 5           // Changed to 5
`define dataWidth 8
`define weightIntWidth 1 // Recommended for accuracy
`define sigmoidSize 10

// Architecture Definition
// Layer 1
`define numNeuronLayer1 40
`define numWeightLayer1 784
`define Layer1ActType "relu"

// Layer 2
`define numNeuronLayer2 40
`define numWeightLayer2 40    // Previous layer had 40 neurons
`define Layer2ActType "relu"

// Layer 3
`define numNeuronLayer3 20
`define numWeightLayer3 40    // Previous layer had 40 neurons
`define Layer3ActType "relu"

// Layer 4
`define numNeuronLayer4 20
`define numWeightLayer4 20    // Previous layer had 20 neurons
`define Layer4ActType "relu"

// Layer 5 (New Output Layer)
`define numNeuronLayer5 10
`define numWeightLayer5 20    // Previous layer had 20 neurons
`define Layer5ActType "relu"
