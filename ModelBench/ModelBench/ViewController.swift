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
    // menu data source
    var settingMenuViewDataSource: [(String, Int, Int)]!
    var settingMenuView = UITableView()
    lazy var benchmark: Benchmark = Benchmark()
    
    @IBOutlet weak var runButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.runButton.isEnabled = true
    }

    @IBAction func RunButtonClicked(_ sender: Any) {
        self.runButton.isEnabled = false
        benchmark.runAndShowBenchmark(viewController:self, runButton:self.runButton)
    }

    @IBAction func settingButtonTouched(_ sender: Any) {
        print("settingButtonTouched")
        settingMenuView.isHidden = !settingMenuView.isHidden
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

