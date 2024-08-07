void process(FrameRange range) override {
  int numsamples = (int)range.count;

  // stretch factor
  int inputNum = numsamples * 1.1;

  float **inputs;
  inputs = (float **)malloc(sizeof(*inputs) * 2 * inputNum);
  for (int i = 0; i < 2; i++) {
    inputs[i] = (float *)malloc(sizeof(float) * inputNum);
    for(int j = 0; j < inputNum; j++)
      if (setRef)
        inputs[i][j] = refArr[i][j + regCount];
      else
        inputs[i][j] = 0.0;
  }

  float **outputs;
  int outputNum = numsamples * 1;
  outputs = (float **)malloc(sizeof(*outputs) * 2 * outputNum);
  for (int i = 0; i < 2; i++) {
    outputs[i] = (float *)malloc(sizeof(float) * outputNum);
  }


  stretch.process(inputs, inputNum, outputs, outputNum);

  for (int j = 0; j < outputNum; j++) {
    cirBuff[0][cirBufPosEnd] = outputs[0][j];
    cirBuff[1][cirBufPosEnd] = outputs[1][j];
    cirBufPosEnd = (cirBufPosEnd + 1) % cirBuffSize;
  }

  for (int i = 0; i < inputNum; i++) {
    float& leftOut = outputSample(0, i);
    float& rightOut = outputSample(1, i);

    if (setRef) {
      leftOut = cirBuff[0][cirBufPosStart];
      rightOut = cirBuff[1][cirBufPosStart];
      regCount++;
      cirBufPosStart = (cirBufPosStart + 1) % cirBuffSize;
    } else {
      leftOut = 0.0;
      rightOut = 0.0;
    }
  }
