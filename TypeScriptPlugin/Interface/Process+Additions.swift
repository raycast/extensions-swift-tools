// Copyright © 2024 Raycast. All rights reserved.

import Foundation

extension Process {
  /// Executes the given `executableURL` as a child process and returns the `stdout` if the child process return a termination status of `0`.
  ///
  /// If the process terminated with a non-zero status, a ``Process/Error`` is thrown with the recorded status, reason, and stdout and stderr data.
  /// - parameter executableURL: The executable binary to be run as a child process.
  /// - parameter arguments: The arguments to pass to the executable binary.
  /// - parameter currentDirectory: The directory from which to run the executable.
  /// - parameter environment: The running environment for the executable.
  /// - parameter priority: The priority at which to run the process. If `nil`, the priority will be inherited from the hosting async context.
  /// - throws: Exclusively throws ``Process/Error`` or `CancellationError`.
  /// - seealso: https://developer.apple.com/forums/thread/690310
  /// - seealso: https://stackoverflow.com/questions/33423993/hanging-nstask-using-waituntilexit
  /// - seealso: https://stackoverflow.com/questions/76914479/read-process-standardoutput-and-standarderror-in-parallel-in-swift-without-block
  @discardableResult static func run(
    _ executableURL: URL,
    arguments: [String] = [],
    currentDirectory currentDirectoryURL: URL? = .none,
    environment: [String: String] = [:],
    priority: TaskPriority = Task.currentPriority
  ) async throws -> Outcome {
    // Check for cancellation before starting to initialize entities.
    try Task.checkCancellation()

    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments
    process.currentDirectoryURL = currentDirectoryURL
    // Passing an empty dictionary to environment makes the child process to fail in certain situations
    // Only set the environment dictionary when strictely necessary.
    if !environment.isEmpty {
      process.environment = environment
    }
    process.qualityOfService = QualityOfService(priority)

    // The state is a "fake" `Sendable` which can only be read/modified from `queue`.
    let state = State()
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "com.raycast.extensions.plugin.ts", qos: DispatchQoS(priority), autoreleaseFrequency: .workItem, target: .none)

    // Termination handler
    group.enter()
    process.terminationHandler = {
      $0.terminationHandler = .none
      queue.async { group.leave() }
    }

    // Standard output handler
    group.enter()
    let stdoutPipe = Pipe()
    process.standardOutput = stdoutPipe

    let stdoutIO = DispatchIO(type: .stream, fileDescriptor: stdoutPipe.fileHandleForReading.fileDescriptor, queue: queue) { errno in
      // This closure is executed once the channel is closed
      try? stdoutPipe.fileHandleForReading.close()
    }

    stdoutIO.read(offset: 0, length: .max, queue: queue) { isDone, data, errorCode in
      state.stdout.append(contentsOf: data ?? .empty)
      guard isDone || errorCode != 0 else { return }
      stdoutIO.close()
      defer { group.leave() }
      guard case .none = state.error, errorCode != 0 else { return }
      let underlyingError = NSError(domain: NSPOSIXErrorDomain, code: Int(errorCode))
      state.error = Process.Error(.standardOutputFailed, stdout: state.stdout, stderr: state.stderr, underlying: underlyingError)
    }

    // Standard error handler
    group.enter()
    let stderrPipe = Pipe()
    process.standardError = stderrPipe

    let stderrIO = DispatchIO(type: .stream, fileDescriptor: stderrPipe.fileHandleForReading.fileDescriptor, queue: queue) { errno in
      // This closure is executed once the channel is closed
      try? stderrPipe.fileHandleForReading.close()
    }

    stderrIO.read(offset: 0, length: .max, queue: queue) { isDone, data, errorCode in
      state.stderr.append(contentsOf: data ?? .empty)
      guard isDone || errorCode != 0 else { return }
      stderrIO.close()
      defer { group.leave() }
      guard case .none = state.error, errorCode != 0 else { return }
      let underlyingError = NSError(domain: NSPOSIXErrorDomain, code: Int(errorCode))
      state.error = Process.Error(.standardErrorFailed, stdout: state.stdout, stderr: state.stderr, underlying: underlyingError)
    }

    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        group.notify(queue: queue) {
          if let error = state.error {
            continuation.resume(throwing: error)
          } else if process.terminationStatus != .zero {
            let error = Process.Error(.nonZeroTermination(status: process.terminationStatus, reason: process.terminationReason), stdout: state.stdout, stderr: state.stderr)
            continuation.resume(throwing: error)
          } else {
            let outcome = Outcome(out: state.stdout, err: state.stderr)
            continuation.resume(returning: outcome)
          }
        }

        queue.async {
          state.hasStarted = true
          if case .none = state.error {
            do {
              return try process.run()
            } catch let error {
              state.error = Process.Error(.unableToStart, stdout: state.stdout, stderr: state.stderr, underlying: error)
            }
          }

          process.terminationHandler = .none
          group.leave()
          stdoutIO.close()
          group.leave()
          stderrIO.close()
          group.leave()
        }
      }
    } onCancel: {
      queue.async {
        guard state.hasStarted else {
          state.error = CancellationError(); return
        }

        guard process.isRunning else { return }

        if case .none = state.error {
          state.error = CancellationError()
        }

        process.terminate()
      }
    }
  }
}

extension Process {
  /// The outcome of a successful (i.e. non-zero termination status) child process.
  struct Outcome: Sendable {
    let stdoutData: Data
    let stderrData: Data

    init(out: Data, err: Data) {
      self.stdoutData = out
      self.stderrData = err
    }

    var stdout: String {
      String(decoding: stdoutData, as: UTF8.self)
    }

    var stderr: String {
      String(decoding: stderrData, as: UTF8.self)
    }
  }

  /// Error thrown by a child process.
  final class Error: Swift.Error {
    public let location: (file: String, function: String, line: Int, column: Int)
    public let timestamp: Date
    public let underlyingError: (any Swift.Error)?

    public let stage: Stage
    public let stdout: Data
    public let stderr: Data

    init(
      _ stage: Stage,
      stdout: Data = Data(),
      stderr: Data = Data(),
      underlying underlyingError: (any Swift.Error)? = nil,
      timestamp: Date = Date(),
      file: String = #fileID, function: String = #function, line: Int = #line, column: Int = #column
    ) {
      self.stage = stage
      self.stdout = stdout
      self.stderr = stderr
      self.location = (file, function, line, column)
      self.timestamp = timestamp
      self.underlyingError = underlyingError
    }

    enum Stage: Sendable {
      case unableToStart
      case standardOutputFailed
      case standardErrorFailed
      case nonZeroTermination(status: Int32, reason: Process.TerminationReason)
    }
  }
}

// MARK: -

extension QualityOfService {
  init(_ taskPriority: TaskPriority) {
    if taskPriority < .medium {
      self = .utility
    } else if taskPriority >= .high {
      self = .userInteractive
    } else {
      self = .default
    }
  }
}

extension DispatchQoS {
  init(_ taskPriority: TaskPriority) {
    if taskPriority < .medium {
      self = .utility
    } else if taskPriority >= .high {
      self = .userInteractive
    } else {
      self = .default
    }
  }
}

// MARK: -

private extension Process {
  /// - attention: State should only be accessed and modified within the process thread.
  final class State: @unchecked Sendable {
    var stdout = Data()
    var stderr = Data()
    /// Indicates whether the process has been started (or at least tried to).
    var hasStarted: Bool = false
    var error: (any Swift.Error)?
  }
}
