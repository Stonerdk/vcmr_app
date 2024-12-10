//
//  MusicTrack.swift
//  ModelBench
//
//  Created by kdk on 12/10/24.
//

struct MusicInfo: Comparable {
    static func == (lhs: MusicInfo, rhs: MusicInfo) -> Bool {
        return lhs.title == rhs.title && lhs.artist == rhs.artist
    }

    static func < (lhs: MusicInfo, rhs: MusicInfo) -> Bool {
        return lhs.score < rhs.score
    }

    let title: String
    let artist: String
    let score: Float
}
