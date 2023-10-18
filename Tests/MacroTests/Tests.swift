import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroImplementation

final class Tests: XCTestCase {
  func testOutputMacro() {
    assertMacroExpansion(
      """
      #exportFunction(toggleCompletionStatus)
      func toggleCompletionStatus(_ reminderId: String) throws {
        let eventStore = EKEventStore()

        guard let item = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
          throw "No reminder found with the provided id"
        }

        item.isCompleted = !item.isCompleted

        do {
          try eventStore.save(item, commit: true)
        } catch {
          throw "Error completing reminder: \\(error.localizedDescription)"
        }
      }

      #exportFunction(deleteReminder)
      func deleteReminder(_ reminderId: String) throws {
        let eventStore = EKEventStore()

        guard let item = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
          throw "No reminder found with the provided id"
        }

        do {
          try eventStore.remove(item, commit: true)
        } catch {
          throw "Error deleting reminder: \\(error.localizedDescription)"
        }
      }
      """,
      expandedSource: """
      RaycastExtension.exportFunction(name: "toggleCompletionStatus", handler: toggleCompletionStatus)
      func toggleCompletionStatus(_ reminderId: String) throws {
        let eventStore = EKEventStore()

        guard let item = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
          throw "No reminder found with the provided id"
        }

        item.isCompleted = !item.isCompleted

        do {
          try eventStore.save(item, commit: true)
        } catch {
          throw "Error completing reminder: \\(error.localizedDescription)"
        }
      }

      RaycastExtension.exportFunction(name: "deleteReminder", handler: deleteReminder)
      func deleteReminder(_ reminderId: String) throws {
        let eventStore = EKEventStore()

        guard let item = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
          throw "No reminder found with the provided id"
        }

        do {
          try eventStore.remove(item, commit: true)
        } catch {
          throw "Error deleting reminder: \\(error.localizedDescription)"
        }
      }
      """,
      macros: [
        "exportFunction": RaycastExportFunctionMacro.self,
      ]
    )
  }
}
