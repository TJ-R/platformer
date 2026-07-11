package main

import "core:fmt"
import sdl "vendor:sdl3"
import gl "vendor:OpenGL"

/*
* Really long breakdown of my understanding of how this seems to work
* SDL can do simple rendering but instead we will passing the work off to 
* whatever opengl library my GPU has on hand (generally implementation written)
* by the manufacturer. Seems like we bind the location of the function calls
* to SDL. I think is via the gl.load_up_to function? 
* 
* Anyways the rendering pipeline has two buffers a front and a back
* The front is what you see and the back is creating the next frame
* SwapWindow while passing the back buffer (window) will display next frame.
* I am assuming it sets the front buffer to the back buffer or dumps the back
* buffer into the front buffer. Then clears the new back buffer or is empty
* as a result of the dump.
*
* SDL handles creating the window, keyboard inputs, audio, networking.
* While OpenGL will handle creating the new frame. To my understanding I just
* passed off the rendering work to a more complex and more competent rendering
* pipeline. I am assuming the same thing works for Vulkan and Metal which I
* believe are two other graphics apis.
*/

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
    sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GL_CONTEXT_PROFILE_CORE))
    
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
