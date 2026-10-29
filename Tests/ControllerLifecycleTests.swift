import AppKit
import ApplicationServices
import XCTest
@testable import Tabbed

final class ControllerLifecycleTests: XCTestCase {
    func testStopRestoresParkedWindowsAndClearsGroups() async {
        await MainActor.run {
            let engine = LifecycleWindowEngine()
            let controller = TabGroupController(engine: engine)
            let frame = CGRect(x: 100, y: 200, width: 800, height: 600)
            let windows = (1...3).map { id in
                ManagedWindow(id: WindowID(id), pid: getpid(),
                              element: AXUIElementCreateApplication(getpid()),
                              title: "Test", appName: "Test", appBundleID: nil)
            }
            let group = TabGroup(windows: windows, activeIndex: 0, contentFrame: frame, spaceID: nil)
            controller.groups = [group]
            controller.mostRecentGroup = group
            engine.deadIDs = [3]
            controller.stop()
            XCTAssertEqual(engine.restoredFrames, [1: frame, 2: frame])
            XCTAssertTrue(controller.groups.isEmpty)
            XCTAssertNil(controller.mostRecentGroup)
            XCTAssertFalse(controller.isRunning)
            controller.stop()
            XCTAssertEqual(engine.moveCount, 2)
        }
    }
}

@MainActor
private final class LifecycleWindowEngine: WindowEngine {
    var restoredFrames: [WindowID: CGRect] = [:]
    var deadIDs: Set<WindowID> = []
    var moveCount = 0
    func setFrame(_ frame: CGRect, of window: ManagedWindow) {
        restoredFrames[window.id] = frame
        moveCount += 1
    }
    func isAlive(_ window: ManagedWindow) -> Bool { !deadIDs.contains(window.id) }
    func window(at point: CGPoint, excluding: Set<WindowID>) -> ManagedWindow? { nil }
    func onScreenWindowFrames(excluding: Set<WindowID>) -> [WindowFrame] { [] }
    func managedWindow(from element: AXUIElement, pid: pid_t) -> ManagedWindow? { nil }
    func frame(of window: ManagedWindow) -> CGRect? { nil }
    func windowServerFrame(of id: WindowID) -> CGRect? { nil }
    func focusedOrMainWindowID(for pid: pid_t) -> WindowID? { nil }
    func frontmostWindowID() -> WindowID? { nil }
    func candidateWindowElements(from element: AXUIElement, pid: pid_t) -> [AXUIElement] { [] }
    func raise(_ window: ManagedWindow) {}
    func activate(_ window: ManagedWindow) {}
    func refreshTitle(_ window: ManagedWindow) -> String { window.title }
    func spaceID(of window: ManagedWindow) -> UInt64? { nil }
    func activeSpaceID() -> UInt64? { nil }
    func move(_ window: ManagedWindow, toSpaceOf reference: ManagedWindow) {}
}
