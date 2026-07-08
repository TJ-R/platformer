package main

import "core:fmt"
import "vendor:sdl3"

main :: proc() {
    if !sdl3.Init({.VIDEO}) {
        fmt.eprintln("Failed to initialize SDL:", sdl3.GetError())
        return
    }
    
    window := sdl3.CreateWindow("Test", 1280, 720, {})
    if window == nil {
        fmt.eprintln("Failed to create window:", sdl3.GetError())
        return
    }
    defer sdl3.DestroyWindow(window)

    renderer := sdl3.CreateRenderer(window, nil)
    if renderer == nil {
        fmt.eprintln("Failed renderer:", sdl3.GetError())
        return
    }
    defer sdl3.DestroyRenderer(renderer)
    
    running := true
    for running {
        event: sdl3.Event
        for sdl3.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    running = false
            }
        }

        sdl3.SetRenderDrawColor(renderer, 40, 44, 52, 255)
        sdl3.RenderClear(renderer)
        sdl3.RenderPresent(renderer)
    }
}
