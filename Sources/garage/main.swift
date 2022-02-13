//
// GarageDoor
//

import Foundation
import ArgumentParser
import SwiftyGPIO

enum ConfigurationConstants {
    static let sensorPin: GPIOName = .P18
    static let buttonPin: GPIOName = .P17
    static let board: SupportedBoard = .RaspberryPiPlusZero
}

class GarageDoorActuator {

    private let sensorPin: GPIO
    private let buttonPin: GPIO

    init(sensorPin: GPIOName, buttonPin: GPIOName, on board: SupportedBoard) throws {
        let gpios = SwiftyGPIO.GPIOs(for: board)

        guard
            let sensorGPIO = gpios[sensorPin],
            let buttonGPIO = gpios[buttonPin] else {
                throw Errors.failedGPIOInit
            }
        buttonGPIO.direction = .OUT
        sensorGPIO.direction = .IN
        sensorGPIO.pull = .up

        self.sensorPin = sensorGPIO
        self.buttonPin = buttonGPIO
    }

    static func defaultActuator() throws -> GarageDoorActuator {
        return try GarageDoorActuator(sensorPin: ConfigurationConstants.sensorPin, buttonPin: ConfigurationConstants.buttonPin, on: ConfigurationConstants.board)
    }

    var isOpen: Bool {
        return self.sensorPin.value == 1
    }

    func pressButton() {
        buttonPin.value = 1
        Thread.sleep(forTimeInterval: 0.5)
        buttonPin.value = 0
    }

}

extension GarageDoorActuator {

    enum Errors: Error {
        case failedGPIOInit
    }

}

struct GarageDoor: ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "A utility for opening and closing a garage door",
        version: "0.1.0",
        subcommands: [Open.self, Close.self, Status.self],
        defaultSubcommand: Status.self
    )


}

extension GarageDoor {

    struct Open: ParsableCommand {

        static var configuration = CommandConfiguration(abstract: "Open the garage door.")

        mutating func run() throws {
            let actuator = try GarageDoorActuator.defaultActuator()
            actuator.pressButton()
            print("OPENING")
        }

    }

    struct Close: ParsableCommand {

        static var configuration = CommandConfiguration(abstract: "Close the garage door.")

        mutating func run() throws {
            let actuator = try GarageDoorActuator.defaultActuator()
            if actuator.isOpen {
                actuator.pressButton()
                print("CLOSING")
            } else {
                print("CLOSED")
            }
        }

    }

    struct Status: ParsableCommand {

        static var configuration = CommandConfiguration(abstract: "Check the status of the garage door.")

        mutating func run() throws {
            let actuator = try GarageDoorActuator.defaultActuator()
            if actuator.isOpen {
                print("OPEN")
            } else {
                print("CLOSED")
            }
        }

    }

}

GarageDoor.main()
