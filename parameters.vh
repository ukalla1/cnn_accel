`ifndef CONSTANTS
    `define CONSTANTS
    
    `define GET_LATENCY
    
    `define data_width 8
    
    `define HT_addrs_width 9
    `define XT_addrs_width 9
    `define number_channel 40
    `define time_stamp 11
    `define output_length 64
    
    `define NUM_LABELS0    256                                                      // output number like 64 nodes
    `define NUM_FEATURES0  `time_stamp * `output_length                           // value after flattening the input image
    `define COEF_ADDRS_WIDTH 18                                               //(log2(NUM_FEATURES*NUM_LABELS))
    `define FEATURE_ADDRS_WIDTH 10
    `define OP_ADDRS_WIDTH 6                                                    //(log2(NUM_LABELS))
    `define NUM_LABELS1    50                                                      // output number like 64 nodes
    `define NUM_FEATURES1  `NUM_LABELS0                           // value after flattening the input image
//    `define NUM_LABELS2    13                                                      // output number like 64 nodes
//    `define NUM_FEATURES2  `NUM_LABELS1                           // value after flattening the input image
    
//    `define featureM 101
//    `define featureN 40
//    `define CONV_FEATURE_ADDRS_WIDTH 12
//    `define weightM 8
//    `define weightN 1
//    `define PE_BUFF_ADDRS_WIDTH 3
//    `define NUM_PE 2
//    `define NUM_WEIGHT_LAYERS 40
//    `define NUM_WEIGHTS `weightM * `weightN * (`NUM_WEIGHT_LAYERS)
//    `define WIGHT_ADDRS_WIDTH 9
//    `define CONV_1D
    
    `define MAX_POOL_ARRDS 12                                                  //log2(NUM_WEIGHTS)
    `define MAX_POOL_IM 94                                       //(((featureM - weightM)+1)*NUM_WEIGHT_LAYERS)
    `define MAX_POOL_IN 40                                       //(((featureN - weightN)+1)*NUM_WEIGHT_LAYERS)
    `define MAX_POOL_WM 8
    `define MAX_POOL_WN 1
    `define MAX_POOL_STRIDE 8
    
    
    `define featureM 6
    `define featureN 6
    `define CONV_FEATURE_ADDRS_WIDTH 6
    `define weightM 4
    `define weightN 4
    `define PE_BUFF_ADDRS_WIDTH 4
    `define NUM_PE 8
    `define NUM_WEIGHT_LAYERS 1
    `define NUM_WEIGHTS `weightM * `weightN * (`NUM_WEIGHT_LAYERS)
    `define WIGHT_ADDRS_WIDTH 4
    
//     `define NUM_LABELS0    4                                                      // output number like 64 nodes
//    `define NUM_FEATURES0  8                          // value after flattening the input image
//    `define COEF_ADDRS_WIDTH 5                                               //(log2(NUM_FEATURES*NUM_LABELS))
//    `define FEATURE_ADDRS_WIDTH 3
//    `define OP_ADDRS_WIDTH 2                                                    //(log2(NUM_LABELS))
//    `define NUM_LABELS1    50                                                      // output number like 64 nodes
//    `define NUM_FEATURES1  `NUM_LABELS0                           // value after flattening the input image
    
`endif