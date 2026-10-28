import Flutter
import UIKit
import XCTest
import ImageIO
@testable import Runner

class RunnerTests: XCTestCase {

  func testOssDownsamplesPanoramaOver9000Pixels() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let source = directory.appendingPathComponent("panorama.png")
    let target = directory.appendingPathComponent("compressed.jpg")
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10000, height: 40), format: format)
    let original = renderer.pngData { context in
      UIColor.red.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 10000, height: 40))
    }
    try original.write(to: source)
    let result = try MDOssImageCompressor.compress(
      source: source.path, target: target.path, maxDimension: 2560,
      quality: 85, maxBytes: 5 * 1024 * 1024
    )
    XCTAssertLessThanOrEqual(result["width"]!, 2560)
    XCTAssertLessThanOrEqual(result["height"]!, 2560)
    XCTAssertGreaterThan(result["width"]!, result["height"]!)
    let data = try Data(contentsOf: target)
    XCTAssertEqual(Array(data.prefix(2)), [0xff, 0xd8])
    XCTAssertLessThanOrEqual(data.count, 5 * 1024 * 1024)
    XCTAssertEqual(try Data(contentsOf: source), original)
  }

  func testOssRejectsInvalidFileAndUnsafeDimensions() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let source = directory.appendingPathComponent("invalid.png")
    let target = directory.appendingPathComponent("compressed.jpg")
    try Data([1, 2, 3]).write(to: source)
    XCTAssertThrowsError(try MDOssImageCompressor.compress(
      source: source.path, target: target.path, maxDimension: 2560,
      quality: 85, maxBytes: 5 * 1024 * 1024
    ))
    XCTAssertThrowsError(try MDOssImageCompressor.compress(
      source: source.path, target: target.path, maxDimension: 9000,
      quality: 85, maxBytes: 5 * 1024 * 1024
    ))
    XCTAssertFalse(FileManager.default.fileExists(atPath: target.path))
  }

  func testExample() {
    // If you add code to the Runner application, consider adding tests here.
    // See https://developer.apple.com/documentation/xctest for more information about using XCTest.
  }

}
