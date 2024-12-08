import Elementary
import Vapor

/// Represents a response that contains HTML content.
///
/// The generated `Response` will have the content type header set to `text/html; charset=utf-8` and a status of `.ok`.
/// The content is renederd in chunks of HTML and streamed in the response body.
///
/// ```swift
/// app.get("hello") { req in
///   HTMLResponse {
///     div {
///       p { "Hello!" }
///     }
///   }
/// }
///
/// NOTE: For non-sendable HTML values, the resulting response body can only be written once.
/// Multiple writes will result in a runtime error.
/// ```
public struct HTMLResponse: Sendable {
    // NOTE: The Sendable requirement on Content can probably be removed in Swift 6 using a sending parameter, and some fancy ~Copyable @unchecked Sendable box type.
    // We only need to pass the HTML value to the response generator body closure
    private let value: _SendableAnyHTMLBox

    /// The number of bytes to write to the response body at a time.
    ///
    /// The default is 1024 bytes.
    public var chunkSize: Int

    /// Response headers
    ///
    /// It can be used to add additional headers to a predefined set of fields.
    ///
    /// - Note: If a new set of headers is assigned, all predefined headers are removed.
    ///
    /// ```swift
    /// var response = HTMLResponse { ... }
    /// response.headers.add(name: "foo", value: "bar")
    /// return response
    /// ```
    public var headers: HTTPHeaders = ["Content-Type": "text/html; charset=utf-8"]

    /// Creates a new HTMLResponse
    ///
    /// - Parameters:
    ///   - chunkSize: The number of bytes to write to the response body at a time.
    ///   - additionalHeaders: Additional headers to be merged with predefined headers.
    ///   - content: The `HTML` content to render in the response.
    public init(chunkSize: Int = 1024, additionalHeaders: HTTPHeaders = [:], @HTMLBuilder content: () -> some HTML & Sendable) {
        self.init(chunkSize: chunkSize, additionalHeaders: additionalHeaders, value: .init(content()))
    }

    #if compiler(>=6.0)
    @available(macOS 15, *)
    /// Creates a new HTMLResponse
    ///
    /// - Parameters:
    ///   - chunkSize: The number of bytes to write to the response body at a time.
    ///   - additionalHeaders: Additional headers to be merged with predefined headers.
    ///   - content: The `HTML` content to render in the response.
    public init(chunkSize: Int = 1024, additionalHeaders: HTTPHeaders = [:], @HTMLBuilder content: () -> sending some HTML) {
        self.init(chunkSize: chunkSize, additionalHeaders: additionalHeaders, value: .init(content()))
    }
    #endif

    init(chunkSize: Int, additionalHeaders: HTTPHeaders = [:], value: _SendableAnyHTMLBox) {
        self.chunkSize = chunkSize
        if additionalHeaders.contains(name: .contentType) {
            self.headers = additionalHeaders
        } else {
            self.headers.add(contentsOf: additionalHeaders)
        }
        self.value = value
    }
}

extension HTMLResponse: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        Response(
            status: .ok,
            headers: self.headers,
            body: .init(asyncStream: { [value, chunkSize] writer in
                guard let html = value.tryTake() else {
                    assertionFailure("Non-sendable HTML value consumed more than once")
                    request.logger.error("Non-sendable HTML value consumed more than once")
                    throw Abort(.internalServerError)
                }
                try await writer.writeHTML(html, chunkSize: chunkSize)
                try await writer.write(.end)
            })
        )
    }
}
