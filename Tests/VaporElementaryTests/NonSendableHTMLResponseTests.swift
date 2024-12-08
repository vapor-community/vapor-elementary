import Elementary
import Vapor
import VaporElementary
import XCTest
import XCTVapor

final class NonSendableHTMLResponseTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
    }

    func testAllowsSendableValuesToBeWrittenTwice() async throws {
        self.app.get { req in
            let html = HTMLResponse { "Hello" }
            _ = try await html.encodeResponse(for: req).body.collect(on: req.eventLoop)
            return html
        }

        let response = try await app.sendRequest(.GET, "/")
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(String(buffer: response.body), #"Hello"#)
    }

    #if compiler(>=6.0)
    func testRespondsWithANonSendable() async throws {
        guard #available(macOS 15.0, *) else {
            throw XCTSkip("Test requires macOS 15.0")
        }
        self.app.get { _ in HTMLResponse { div { NonSendableHTML() } } }

        let response = try await app.sendRequest(.GET, "/")
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(String(buffer: response.body), #"<div>Hello</div>"#)
    }
    #endif
}

@available(*, unavailable)
extension NonSendableHTML: Sendable {}

struct NonSendableHTML: HTML {
    var content: some HTML {
        "Hello"
    }
}
