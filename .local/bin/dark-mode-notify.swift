// This a modified version of bouk/dark-mode-notify on GitHub
// License: MIT (https://github.com/bouk/dark-mode-notify/blob/main/LICENSE)
// Copyright (c) 2021 Bouke van der Bijl
// I ship this with dotfiles for convenience

import Cocoa

@discardableResult
func shell(_ args: [String]) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.standardError = FileHandle.standardError
    task.standardOutput = FileHandle.standardOutput
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

let args = Array(CommandLine.arguments.suffix(from: 1))
shell(args)

DistributedNotificationCenter.default.addObserver(
    forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: nil) { (notification) in
        shell(args)
}

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification,
    object: nil,
    queue: nil) { (notification) in
    shell(args)
}

NSApplication.shared.run()
