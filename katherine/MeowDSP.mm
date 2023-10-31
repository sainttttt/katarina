// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#include "DSPBase.h"
#include "ParameterRamper.h"
#include "signalsmith-stretch.h"
#include "katherine-Swift.h"


enum MeowParameter : AUParameterAddress {
    MeowParameterLeftGain,
    MeowParameterRightGain,
    MeowParameterFlipStereo,
    MeowParameterMixToMono
};


struct MeowDSP : DSPBase {
private:
    ParameterRamper leftGainRamp{1.0};
    ParameterRamper rightGainRamp{1.0};
    bool flipStereo = false;
    bool mixToMono = false;
    float **cirBuff;
    int regCount = 0;
    int cirBufPosStart = 0;
    int cirBufPosEnd = 0;
    int cirBuffSize = 240000000;
    float **refArr;
    bool setRef = false;
    signalsmith::stretch::SignalsmithStretch<float> stretch;

public:
    MeowDSP() : DSPBase(1, true) {
        parameters[MeowParameterLeftGain] = &leftGainRamp;
        parameters[MeowParameterRightGain] = &rightGainRamp;
        stretch.presetDefault(2, sampleRate);
        NSLog(@"woof %f", sampleRate);


        cirBuff = (float **)malloc(sizeof(*cirBuff) * 2 * cirBuffSize);
        for (int i = 0; i < 2; i++) {
          cirBuff[i] = (float *)malloc(sizeof(float) * cirBuffSize);
     //     for(int j = 0; j < cirBuffSize; j++)
//            cirBuff[i][j] = 0;
        }

//        stretch.presetCheaper(2, sampleRate);
    }

    void meow3(const char *sound, float **arr, int frameLength) override {
      //katherine::printWelcomeMessage("Theo");


      if (setRef) {
        printf("setref here meow3 %s --- %f \n", sound, refArr[1][4]);
      } else {
        printf("no setref \n");
      }

      refArr = (float **)malloc(sizeof(*refArr) * 2 * frameLength);
      for (int i = 0; i < 2; i++) {
        refArr[i] = (float *)malloc(sizeof(float) * frameLength);
      }


      //std::copy(&arr[0][0], &arr[0][0]+2*frameLength,&refArr[0][0]);

      for (int i = 0; i < 2; i++) {
        for (int j = 0; j < frameLength; j++) {
          refArr[i][j] = arr[i][j];
        }
      }



      //refArr = arr;
      printf("here meow3 %s --- %f %d\n", sound, refArr[1][4], frameLength);
      setRef = true;

    }

    // Uses the ParameterAddress as a key
    void setParameter(AUParameterAddress address, AUValue value, bool immediate) override {
        switch (address) {
            case MeowParameterFlipStereo:
                flipStereo = value > 0.5f;
                break;
            case MeowParameterMixToMono:
                mixToMono = value > 0.5f;
                break;
            default:
                DSPBase::setParameter(address, value, immediate);
        }
    }

    // Uses the ParameterAddress as a key
    float getParameter(AUParameterAddress address) override {
        switch (address) {
            case MeowParameterFlipStereo:
                return flipStereo ? 1.f : 0.f;
            case MeowParameterMixToMono:
                return mixToMono ? 1.f : 0.f;
            default:
                return DSPBase::getParameter(address);
        }
    }

    void meow2() {
      NSLog(@"meow 22 22");
    }

    void resetDSP(DSPRef pDSP) {
      NSLog(@"meow 22 22");
    }

    void startRamp(const AUParameterEvent &event) override {
        auto address = event.parameterAddress;
        switch (address) {
            case MeowParameterFlipStereo:
                flipStereo = event.value > 0.5f;
                break;
            case MeowParameterMixToMono:
                mixToMono = event.value > 0.5f;
                break;
            default:
                DSPBase::startRamp(event);
        }
    }

    void process(FrameRange range) override {

      if (range.count <= 0) {
//        NSLog(@"none");
        return;
      }

      if (setRef) {
        //printf("refArr %f\n", refArr[1][11234]);
        //setRef = false;
      }



      int numsamples = (int)range.count;

       //NSLog(@"%d", numsamples);

      stretch.setTransposeFactor(0.5); // up one octave
      //stretch.setTransposeSemitones(-12)

      stretch.setTransposeSemitones(3, 8000/sampleRate);
      int inputNum = numsamples * 1;

      float **inputs;
      inputs = (float **)malloc(sizeof(*inputs) * 2 * inputNum);
      for (int i = 0; i < 2; i++) {
        inputs[i] = (float *)malloc(sizeof(float) * inputNum);
        for(int j = 0; j < inputNum; j++)
          inputs[i][j] = inputSample(i, j);
      }

      float **outputs;
      int outputNum = numsamples * 1.2;
      outputs = (float **)malloc(sizeof(*outputs) * 2 * outputNum);
      for (int i = 0; i < 2; i++) {
        outputs[i] = (float *)malloc(sizeof(float) * outputNum);
        for(int j = 0; j < outputNum; j++)
          outputs[i][j] = 0;
      }


      stretch.process(inputs, inputNum, outputs, outputNum);

      for (int j = 0; j < outputNum; j++) {
        cirBuff[0][cirBufPosEnd] = outputs[0][j];
        cirBuff[1][cirBufPosEnd] = outputs[1][j];
        cirBufPosEnd = (cirBufPosEnd + 1) % cirBuffSize;
      }

      int delay = 0;
      for (int i = 0; i < inputNum; i++) {
        float& leftOut = outputSample(0, i);
        float& rightOut = outputSample(1, i);

        //if (cirBufPosEnd > delay) {
        if (setRef) {
          //leftOut = cirBuff[0][cirBufPosStart];
          //rightOut = cirBuff[1][cirBufPosStart];

          leftOut = refArr[0][regCount];
          rightOut = refArr[1][regCount];
          regCount++;
          cirBufPosStart = (cirBufPosStart + 1) % cirBuffSize;
        } else {
          leftOut = 0.0;
          rightOut = 0.0;
        }
      }



      /*
         for (auto i : range) {

         float leftIn = inputSample(0, i);
         float rightIn = inputSample(1, i);

         float& leftOut = outputSample(0, i);
         float& rightOut = outputSample(1, i);

         float leftGain = leftGainRamp.getAndStep();
         float rightGain = rightGainRamp.getAndStep();

         if (mixToMono) {
         leftOut = rightOut = 0.5 * (leftIn * leftGain + rightIn * rightGain);
         } else {

         if (flipStereo) {
         std::swap(leftIn, rightIn);
         }

      //stretch.process(inputBuffers, inputSamples, outputBuffers, outputSamples);

      leftOut = outputs[0][i];
      rightOut = outputs[1][i];

      }
      }
       */
    }
};


  AK_REGISTER_DSP(MeowDSP, "meow")
  AK_REGISTER_PARAMETER(MeowParameterLeftGain)
  AK_REGISTER_PARAMETER(MeowParameterRightGain)
  AK_REGISTER_PARAMETER(MeowParameterFlipStereo)
AK_REGISTER_PARAMETER(MeowParameterMixToMono)
