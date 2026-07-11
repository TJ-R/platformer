package main

import "core:fmt"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"

main :: proc() {
    if !sdl.Init({.VIDEO}) {
        fmt.eprintln("Failed to initialize SDL:", sdl.GetError())
        return
    }

    fmt.println("[Debug] Video Initialized")

    // Setting the OpenGL setting the version and match
    // not 100% guarentteed that I get it but will need
    // to check afterwards
    sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
    sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 3)
    //sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GL_CONTEXT_PROFILE_CORE))
    
    window := sdl.CreateWindow("Test", 1280, 720, {.OPENGL})
    if window == nil {
        fmt.eprintln("Failed to create window:", sdl.GetError())
        return
    }
    defer sdl.DestroyWindow(window)

    fmt.println("[Debug] Window Initialized")

    // Creating the ctx for OpenGL based on SDL's window
    ctx := sdl.GL_CreateContext(window)
    if ctx == nil {
        fmt.eprintln("Failed to create ctx:", sdl.GetError())
        return
    }
    defer sdl.GL_DestroyContext(ctx)

    fmt.println("[Debug] Context Created")

    sdl.GL_MakeCurrent(window, ctx)

    // Have to load the proc address to call gl funcdtions
    gl.load_up_to(3, 3, sdl.gl_set_proc_address)

    gl.Viewport(0, 0, 1280, 720)

    running := true
    for running {
        event: sdl.Event
        for sdl.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    running = false
                    break
                case .WINDOW_RESIZED:
                    gl.Viewport(0, 0, event.window.data1, event.window.data2)
            }
        }

        // Sets the color of the screen durning the clear screen
        gl.ClearColor(0, 0, 0, 1)

        // Clears the screen using the Clear Color
        gl.Clear(gl.COLOR_BUFFER_BIT)

        fmt.println("[DEBUG] Swapping Buffers")
        sdl.GL_SwapWindow(window)
    }

    sdl.Quit()
}
