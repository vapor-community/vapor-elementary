import Elementary
import Vapor
import VaporElementary
import XCTest
import XCTVapor

final class HTMLResponseTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
    }

    func testSetsHeadersAndStatus() async throws {
        self.app.get { _ in HTMLResponse { EmptyHTML() } }

        let response = try await app.sendRequest(.GET, "/")
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(response.headers.contentType?.description, "text/html; charset=utf-8")
        XCTAssertEqual(response.body.readableBytes, 0)
    }

    func testRespondsWithAPage() async throws {
        self.app.get { _ in HTMLResponse { TestPage() } }

        let response = try await app.sendRequest(.GET, "/")
        XCTAssertEqual(String(buffer: response.body), #"<!DOCTYPE html><html><head><title>Test Page</title><link rel="stylesheet" href="/styles.css"></head><body><h1 id="foo">bar</h1></body></html>"#)
    }

    func testRespondsWithAFragment() async throws {
        self.app.get { _ in HTMLResponse { p {} } }

        let response = try await app.sendRequest(.GET, "/")
        XCTAssertEqual(String(buffer: response.body), #"<p></p>"#)
    }

    func testRespondsWithALargeDocument() async throws {
        let count = 1000
        self.app.get { _ in HTMLResponse {
            for _ in 0..<count {
                p {}
            }
        } }

        let response = try await app.sendRequest(.GET, "/")
        XCTAssertEqual(String(buffer: response.body), Array(repeating: "<p></p>", count: count).joined())
    }
}

struct TestPage: HTMLDocument {
    var title: String { "Test Page" }

    var head: some HTML {
        link(.rel(.stylesheet), .href("/styles.css"))
    }

    var body: some HTML {
        h1(.id("foo")) { "bar" }
    }
}
