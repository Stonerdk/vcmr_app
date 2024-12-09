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
}

func loadMusicEmbeddings() -> MusicEmbeddingsData? {
    guard let url = Bundle.main.url(forResource: "music_embeddings", withExtension: "bin") else {
        print("music_embeddings.bin 파일을 찾을 수 없습니다.")
        return nil
    }
    
    do {
        let data = try Data(contentsOf: url)
        let musicEmbeddingsProto = try MusicEmbeddings(serializedBytes: data)
        
        var filenames: [String] = []
        var embeddings: [Float] = []
        
        for embeddingMessage in musicEmbeddingsProto.embeddings {
            filenames.append(embeddingMessage.filename)
            embeddings.append(contentsOf: embeddingMessage.embedding)
        }
        
        return MusicEmbeddingsData(filenames: filenames, embeddings: embeddings)
    } catch {
        print("파일 읽기 또는 디코딩 에러: \(error)")
        return nil
    }
}

//
//if let musicEmbeddings = loadMusicEmbeddings() {
//    for embedding in musicEmbeddings {
//        print("파일명: \(embedding.filename), 임베딩 길이: \(embedding.embedding.count)")
//    }
//} else {
//    print("임베딩 데이터를 로드할 수 없습니다.")
//}
