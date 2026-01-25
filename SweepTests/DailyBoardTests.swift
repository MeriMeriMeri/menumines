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

    func testDifferentDaysProduceDifferentBoards() {
        // 2024-03-15 00:00:00 UTC
        let date1 = Date(timeIntervalSince1970: 1_710_465_600)
        // 2024-03-16 00:00:00 UTC (24 hours later)
        let date2 = Date(timeIntervalSince1970: 1_710_465_600 + 86400)

        let board1 = boardForDate(date1)
        let board2 = boardForDate(date2)

        XCTAssertNotEqual(board1.cells, board2.cells)
        XCTAssertEqual(seedFromDate(date1), 20240315)
        XCTAssertEqual(seedFromDate(date2), 20240316)
    }

    func testLateNightUTCConsistency() {
        // 2024-03-15 00:00:00 UTC (start of day)
        let startOfDay = Date(timeIntervalSince1970: 1_710_465_600)
        // 2024-03-15 23:00:00 UTC (late night same day)
        let lateNight = Date(timeIntervalSince1970: 1_710_465_600 + 23 * 3600)

        XCTAssertEqual(seedFromDate(startOfDay), seedFromDate(lateNight))
        XCTAssertEqual(seedFromDate(lateNight), 20240315)

        let board1 = boardForDate(startOfDay)
        let board2 = boardForDate(lateNight)
        XCTAssertEqual(board1.cells, board2.cells)
    }
}
