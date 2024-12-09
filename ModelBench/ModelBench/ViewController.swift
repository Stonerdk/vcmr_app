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
import PhotosUI

let inferenceQueue = DispatchQueue(label: "inferenceQueue")

@available(iOS 16.0, *)
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, PHPickerViewControllerDelegate {
    // menu data source
    var settingMenuViewDataSource: [(String, Int, Int)]!
    var settingMenuView = UITableView()
    var musicList: [MusicInfo] = []
    lazy var benchmark: Benchmark = Benchmark()
    
    @IBOutlet weak var runButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var musicStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.runButton.isEnabled = true

    }

    @IBAction func RunButtonClicked(_ sender: Any) {
        self.runButton.isEnabled = false
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let provider = results.first?.itemProvider else { return }
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    if let selectedImage = image as? UIImage {
                        self?.imageView.image = selectedImage // Display the image (optional)
                        self?.benchmark.runAndShowBenchmark(viewController:self!, runButton:self!.runButton, image: selectedImage) { [weak self] topKTracks in
                            self?.musicList = topKTracks
                            self?.populateMusicStackView()
                            self?.runButton.isEnabled = true
                        }
                    }
                }
            }
        }
    }
    
    func populateMusicStackView() {
        for view in musicStackView.arrangedSubviews {
            musicStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        for track in musicList {
            let trackView = MusicTrackView()
            trackView.configure(with: track)
            musicStackView.addArrangedSubview(trackView)
            NSLayoutConstraint.activate([
                trackView.heightAnchor.constraint(equalToConstant: 60)
            ])
        }
    }

    @IBAction func settingButtonTouched(_ sender: Any) {
        print("settingButtonTouched")
        settingMenuView.isHidden = !settingMenuView.isHidden
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

