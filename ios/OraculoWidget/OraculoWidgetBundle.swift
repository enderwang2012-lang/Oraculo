import SwiftUI
import WidgetKit

@main
struct OraculoWidgetBundle: WidgetBundle {
    var body: some Widget {
        OraculoHomeWidget()
        OraculoLockInlineWidget()
        OraculoLockRectangularWidget()
    }
}
