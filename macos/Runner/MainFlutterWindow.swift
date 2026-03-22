import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // Set window size for kiosk (9:16 aspect ratio)
    let windowSize = NSSize(width: 540, height: 960)
    let screenSize = NSScreen.main?.frame.size ?? NSSize(width: 1920, height: 1080)
    let windowOrigin = NSPoint(
      x: (screenSize.width - windowSize.width) / 2,
      y: (screenSize.height - windowSize.height) / 2
    )
    
    let windowFrame = NSRect(origin: windowOrigin, size: windowSize)
    self.setFrame(windowFrame, display: true)
    
    // Allow resize for testing purposes
    self.minSize = NSSize(width: 400, height: 700)
    self.styleMask.insert(.resizable)
    
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
