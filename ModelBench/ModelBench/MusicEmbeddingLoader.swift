//
//  MusicEmbeddingLoader.swift
//  ModelBench
//
//  Created by kdk on 12/9/24.
//

import Foundation
import SwiftProtobuf


struct MusicEmbeddingsData {
    let filenames: [String]
    let embeddings: [Float] // Flat array, size = numEmbeddings * 256
    let artists: [String]
    let tracks: [String]
}

func loadMusicEmbeddings() -> MusicEmbeddingsData? {
    guard let url = Bundle.main.url(forResource: "music_embeddings", withExtension: "bin") else {
        print("music_embeddings.bin 파일을 찾을 수 없습니다.")
        return nil
    }
    
    do {
        let data = try Data(contentsOf: url)
        let musicEmbeddingsProto = try MusicEmbeddings(serializedBytes: data)
        
        var filenames: [String] = musicEmbeddingsProto.filenames
        var artists: [String] = musicEmbeddingsProto.artists
        var tracks: [String] = musicEmbeddingsProto.tracks
        var embeddings: [Float] = []
        
        for embeddingMessage in musicEmbeddingsProto.embeddings {
            embeddings.append(contentsOf: embeddingMessage.embedding)
        }
        
        return MusicEmbeddingsData(filenames: filenames, embeddings: embeddings, artists: artists, tracks: tracks)
    } catch {
        print("파일 읽기 또는 디코딩 에러: \(error)")
        return nil
    }
}
