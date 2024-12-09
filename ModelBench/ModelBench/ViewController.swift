//
//  ViewController.swift
//  ModelBench
//
//  For licensing see accompanying LICENSE file.
//  Abstract:
//  The app's primary view controller that presents the benchmark interface.
//

import UIKit
import CoreML

let inferenceQueue = DispatchQueue(label: "inferenceQueue")

@available(iOS 16.0, *)
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    // Benchmark configuration and data
    var rounds: Int = 20
    var inferencesPerRound: Int = 50
    let warmUps: Int = 1
    var trims: Int = 10
    var running: Bool = false
    var averageLatency: Double = 0.0
    var latencyLow: Double = .infinity
    var latencyHigh: Double = 0.0
    var latencies: [Double] = []
    var roundsLatencies: [[Double]] = []
    var averagies: [Double] = []
    var averageAll: Double = .infinity

    lazy var modelImageEncoder: ImageEncoder_float32 = try! ImageEncoder_float32(configuration: MLModelConfiguration())
    lazy var modelMLP: MLP_transformer = try! MLP_transformer(configuration: MLModelConfiguration())
    lazy var musicEmbeddings: MusicEmbeddingsData! = loadMusicEmbeddings()

    // menu data source
    var settingMenuViewDataSource: [(String, Int, Int)]!
    var settingMenuView = UITableView()

    @IBOutlet weak var averageAllLatencyField: UITextField!
    @IBOutlet weak var averageLastLatencyField: UITextField!
    @IBOutlet weak var latencyLowField: UITextField!
    @IBOutlet weak var latencyHighField: UITextField!

    @IBOutlet weak var runButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()


        setupSettingMenuView()
        settingMenuView.isHidden = true
    }

    @IBAction func RunButtonClicked(_ sender: Any) {
        self.roundsLatencies = []
        self.runButton.isEnabled = false
        self.averageAllLatencyField.text = ""
        self.averageLastLatencyField.text = ""
        self.latencyLowField.text = ""
        self.latencyHighField.text = ""

        self.averagies.removeAll()
        self.latencyLow = .infinity
        self.latencyHigh = 0.0
        self.trims = min(self.trims, (self.inferencesPerRound - 1) / 2)

        runAndShowBenchmark()
    }

    @IBAction func settingButtonTouched(_ sender: Any) {
        print("settingButtonTouched")
        settingMenuView.isHidden = !settingMenuView.isHidden
    }

    @IBAction func menuItemValueChanged(_ sender: UITextField!)
    {
        if let value = Int(sender.text ?? "0") {
            if sender.tag == 0 {
                self.rounds = value
            } else if sender.tag == 1 {
                self.inferencesPerRound = value
            } else if sender.tag == 2 {
                self.trims = value
            } else {
                print("UISwitch tag not known")
            }
        }
    }
    
    func preprocessImageForEncoder() -> CVPixelBuffer? {
        let dummyImage = UIImage(systemName: "photo")!  // 실제 이미지를 사용하는 대신 샘플 이미지 사용
        let resizedImage = resizeImageTo256x256(image: dummyImage)
        return convertToPixelBuffer(from: resizedImage!)
    }

    func resizeImageTo256x256(image: UIImage) -> UIImage? {
        let size = CGSize(width: 256, height: 256)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func convertToPixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let width = 256
        let height = 256
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        if let context = context, let cgImage = image.cgImage {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        return buffer
    }


    // Main function to perform a benchmark session
    func runAndShowBenchmark() {
        inferenceQueue.async { [self] in
            self.latencies.reserveCapacity(self.inferencesPerRound)
            let attributes = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, nil, nil);
            var pixelBuffer256x256: CVPixelBuffer? = nil
            let _: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault, 256, 256,
                kCVPixelFormatType_32BGRA,
                attributes, &pixelBuffer256x256)


            self.latencies.removeAll()
            for inference in -self.warmUps..<self.inferencesPerRound {
                let predictStart = Date()
                guard let new_pixel = preprocessImageForEncoder() else {
                    fatalError("Could not preprocess image to 256x256 CVPixelBuffer")
                }
                let new_input = ImageEncoder_float32Input(colorImage: new_pixel)
                let encoder_output = try? modelImageEncoder.prediction(input:new_input)
                if encoder_output == nil {
                    fatalError("An error occured while inferencing CLIP ImageEncoder.")
                }
                let mlp_output = try? modelMLP.prediction(input:encoder_output!.embOutput)
                if mlp_output == nil {
                    fatalError("An error occured while inferencing MLP.")
                }
                
                let mlp_output_f32 = convertMLMultiArrayToFloatArray(mlp_output!.output)
                let topKResults = computeTopKSimilarities(input:mlp_output_f32, embeddingsData:musicEmbeddings, topK:10);
                
                print("Computation Done...");
                
                print(topKResults);

                let predictTime = 1000.0 * Date().timeIntervalSince(predictStart)
                // ignore the warmup benchmark inferences result
                if inference < 0 {
                    continue
                }
                self.latencies.append(predictTime)
            }

            self.updateLatencies()
            self.updateLatencyStatsDisplay()

        }
    }

    func updateLatencies() {

        // Sort then trim latencies
        self.latencies.sort()
        let trimmed_latencies = latencies[self.trims..<(self.inferencesPerRound - self.trims)]

        // Calculate latency averages.
        self.averageLatency =
            trimmed_latencies.reduce(0.0, +) / Double(trimmed_latencies.count)
        self.averagies.append(self.averageLatency)
        self.averageAll = self.averagies.reduce(0.0, +) / Double(self.averagies.count)

        if let low = trimmed_latencies.first {
            self.latencyLow = min(self.latencyLow, low)
        }
        if let high = trimmed_latencies.last {
            self.latencyHigh = max(self.latencyHigh, high)
        }

        self.roundsLatencies.append(self.latencies)
    }

    func updateLatencyStatsDisplay() {
        DispatchQueue.main.async {
            self.averageAllLatencyField.text = String(format: "%.3f", self.averageAll)
            self.averageLastLatencyField.text = String(format: "%.3f", self.averageLatency)
            self.latencyLowField.text = String(format: "%.3f", self.latencyLow)
            self.latencyHighField.text = String(format: "%.3f", self.latencyHigh)
        }
    }

    func setupSettingMenuView() {
        settingMenuViewDataSource = [
            ("Rounds", self.rounds, 0),
            ("Inferences per Round", self.inferencesPerRound, 1),
            ("Low/High Trim", self.trims, 2)
        ]
        settingMenuView.translatesAutoresizingMaskIntoConstraints = false
        settingMenuView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.90)
        settingMenuView.layer.borderWidth = 1
        settingMenuView.layer.borderColor = UIColor.yellow.cgColor
        settingMenuView.layer.cornerRadius = 5
        settingMenuView.allowsSelection = false

        self.view.addSubview(settingMenuView)
        settingMenuView.frame = CGRect(x: 80, y: 100, width: 200, height: 100)

        settingMenuView.isScrollEnabled = true
        settingMenuView.delegate = self
        settingMenuView.dataSource = self
        settingMenuView.register(SettingMenuViewCell.self,
            forCellReuseIdentifier: "SettingMenuViewCell")

        let widthConstraint = NSLayoutConstraint(
            item: settingMenuView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil,
            attribute: .notAnAttribute, multiplier: 1, constant: 220)
        let heightConstraint = NSLayoutConstraint(
            item: settingMenuView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil,
            attribute: .notAnAttribute, multiplier: 1,
            constant: CGFloat(40 * settingMenuViewDataSource.count))
        let leadingContraint = NSLayoutConstraint(
            item: settingMenuView, attribute: .leading, relatedBy: .equal, toItem: settingButton,
            attribute: .leading, multiplier: 1, constant: 0)
        let bottomContraint = NSLayoutConstraint(
            item: settingMenuView, attribute: .bottom, relatedBy: .equal, toItem: settingButton,
            attribute: .top, multiplier: 1, constant: 0)

        view.addConstraints([widthConstraint, heightConstraint, leadingContraint, bottomContraint])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        settingMenuViewDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView
            .dequeueReusableCell(withIdentifier: "SettingMenuViewCell",
            for: indexPath) as? SettingMenuViewCell
            else {
            fatalError("unable to deque SettingMenuViewCell")
        }

        let dataSource = settingMenuViewDataSource[indexPath.row]
        cell.labelView.text = dataSource.0
        cell.valueView.text = String(dataSource.1)
        cell.valueView.tag = dataSource.2
        cell.valueView.addTarget(self, action: #selector(menuItemValueChanged(_:)), for: UIControl.Event.editingChanged)
        cell.valueView.delegate = self
        cell.valueView.returnKeyType = .done
        cell.backgroundView = nil
        cell.backgroundColor = .clear
        cell.selectionStyle = .blue

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }

}

