import XCTest
@testable import Sweep

final class DailyBoardTests: XCTestCase {
    func testSeedFromDateUsesUTCComponents() {
        var calendar = Calendar(identifier: .gregorian)
        guard let utc = TimeZone(identifier: "UTC") else {
            XCTFail("Missing UTC time zone")
            return
        }
        calendar.timeZone = utc

        var components = DateComponents()
        components.calendar = calendar
        components.year = 2024
        components.month = 3
        components.day = 15
        components.hour = 12
        components.minute = 34

        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to construct date")
            return
        }

        XCTAssertEqual(seedFromDate(date), 20240315)
    }

    func testSeedFromDateIsUTCConsistent() {
        var calendar = Calendar(identifier: .gregorian)
        guard let pacific = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("Missing Pacific time zone")
            return
        }
        calendar.timeZone = pacific

        var components = DateComponents()
        components.calendar = calendar
        components.year = 2024
        components.month = 3
        components.day = 14
        components.hour = 17
        components.minute = 0

        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to construct date")
            return
        }

        // 2024-03-14 17:00 in Los Angeles is 2024-03-15 00:00 UTC.
        XCTAssertEqual(seedFromDate(date), 20240315)
    }

    func testBoardForDateIsDeterministic() {
        let date = Date(timeIntervalSince1970: 1_710_465_600) // 2024-03-15 00:00:00 UTC
        let board1 = boardForDate(date)
        let board2 = boardForDate(date)

        XCTAssertEqual(board1.cells, board2.cells)
    }
}
