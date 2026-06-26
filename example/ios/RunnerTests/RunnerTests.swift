import Flutter
import UIKit
import XCTest

@testable import xue_hua_gaode_map

class RunnerTests: XCTestCase {
  func testPluginRegisters() {
    let plugin = XueHuaGaodeMapPlugin()
    XCTAssertNotNil(plugin)
  }
}
