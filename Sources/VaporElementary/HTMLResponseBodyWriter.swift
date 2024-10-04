import Elementary
import Vapor

struct HTMLResponseBodyStreamWriter: HTMLStreamWriter {
    let allocator: ByteBufferAllocator = .init()
    var writer: any AsyncBodyStreamWriter

    mutating func write(_ bytes: ArraySlice<UInt8>) async throws {
        try await self.writer.writeBuffer(self.allocator.buffer(bytes: bytes))
    }
}

public extension AsyncBodyStreamWriter {
    /// Writes HTML by rendering chuncks of bytes to the response body
    ///
    /// - Parameters:
    ///   - html: The HTML content to render in the response
    ///   - chunkSize: The number of bytes to write to the response body at a time (default is 1024 bytes)
    func writeHTML(_ html: consuming some HTML, chunkSize: Int = 1204) async throws {
        try await html.render(
            into: HTMLResponseBodyStreamWriter(writer: self),
            chunkSize: chunkSize
        )
    }
}
