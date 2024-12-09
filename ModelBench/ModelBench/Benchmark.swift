import Foundation
import CoreML
import Accelerate
import UIKit

@available(iOS 16.0, *)
class Benchmark {
    var inferencesPerRound: Int = 50
    let warmUps: Int = 1
    
    lazy var modelImageEncoder: ImageEncoder_float32 = try! ImageEncoder_float32(configuration: MLModelConfiguration())
    lazy var modelMLP: MLP_transformer = try! MLP_transformer(configuration: MLModelConfiguration())
    lazy var musicEmbeddings: MusicEmbeddingsData! = loadMusicEmbeddings()
    
    func runAndShowBenchmark(viewController: ViewController, runButton: UIButton) {
        inferenceQueue.async {[self] in
            var imageProcessingTime: Double = 0.0
            var clipEncodingTime: Double = 0.0
            var mlpInferenceTime: Double = 0.0
            var topKTime: Double = 0.0
            
            for inference in -self.warmUps..<self.inferencesPerRound {
                let phase0 = Date()
                guard let new_pixel = preprocessImageForEncoder() else {
                    fatalError("Could not preprocess image to 256x256 CVPixelBuffer")
                }
                let new_input = ImageEncoder_float32Input(colorImage: new_pixel)
                
                let phase1 = Date()
                let encoder_output = try? self.modelImageEncoder.prediction(input:new_input)
                if encoder_output == nil {
                    fatalError("An error occured while inferencing CLIP ImageEncoder.")
                }
                
                let phase2 = Date()
                let mlp_output = try? self.modelMLP.prediction(input:encoder_output!.embOutput)
                if mlp_output == nil {
                    fatalError("An error occured while inferencing MLP.")
                }
                
                let phase3 = Date()
                let mlp_output_f32 = convertMLMultiArrayToFloatArray(mlp_output!.output)
                let topKResults = computeTopKSimilarities(input:mlp_output_f32, embeddingsData:self.musicEmbeddings, topK:10);
                
                let phase4 = Date()
                print("Computation Done...");
                
                print(topKResults);
                
                if inference < 0 { // warmup
                    continue
                }
                
                imageProcessingTime += 1000 * phase1.timeIntervalSince(phase0)
                clipEncodingTime += 1000 * phase2.timeIntervalSince(phase1)
                mlpInferenceTime += 1000 * phase3.timeIntervalSince(phase2)
                topKTime += 1000 * phase4.timeIntervalSince(phase3)
            }
            imageProcessingTime /= Double(self.inferencesPerRound)
            clipEncodingTime /= Double(self.inferencesPerRound)
            mlpInferenceTime /= Double(self.inferencesPerRound)
            topKTime /= Double(self.inferencesPerRound)
            print(imageProcessingTime, clipEncodingTime, mlpInferenceTime, topKTime)
            DispatchQueue.main.async {
                runButton.isEnabled = true
            }
        }
    }
}

