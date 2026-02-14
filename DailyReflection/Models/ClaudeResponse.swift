// ClaudeResponse.swift
import Foundation

nonisolated struct ClaudeResponse: Decodable {
    let content: [ClaudeContent]
}

nonisolated struct ClaudeContent: Decodable {
    let text: String
}
