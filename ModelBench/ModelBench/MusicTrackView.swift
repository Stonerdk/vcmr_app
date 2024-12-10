//
//  MusicTrackView.swift
//  ModelBench
//
//  Created by kdk on 12/10/24.
//

import UIKit

class MusicTrackView: UIView {

    private let blurEffectView: UIVisualEffectView = {
        // .light, .dark, .extraLight
        let blurEffect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let artistLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    // Storyboard/XIB
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        self.backgroundColor = UIColor(white: 0.95, alpha: 0.4)
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(blurEffectView)
        self.addSubview(titleLabel)
        self.addSubview(artistLabel)
        
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: self.leadingAnchor, constant: 300),
        
            artistLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 6),
            artistLabel.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: -100),
            artistLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
//            artistLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8)
        ])
        
        self.heightAnchor.constraint(equalToConstant: 30).isActive = true

    }
    
    func configure(with track: MusicInfo) {
        titleLabel.text = track.title
        artistLabel.text = track.artist
    }
}
