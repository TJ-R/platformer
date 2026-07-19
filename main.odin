package main

import "core:fmt"
import "core:math"
import "core:strings"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

/*
* Really long breakdown of my understanding of how this seems to work
* SDL can do simple rendering but instead we will passing the work off to 
* whatever opengl library my GPU has on hand (generally implementation written)
* by the manufacturer. Seems like we bind the location of the function calls
* to SDL. I think is via the gl.load_up_to function? 
* 
* Anyways the rendering pipeline has two buffers a front and a back
* The front is what you see and the back is creating the next frame
* SwapWindow while passing the back buffer (window) will display next frame. I am assuming it sets the front buffer to the back buffer or dumps the back
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

	// 16:9 aspect ratio
	width, height: i32
	width = 16 * 80
	height = 9 * 80

	// Have to load the proc address to call gl funcdtions
	gl.load_up_to(3, 3, sdl.gl_set_proc_address)
	gl.Viewport(0, 0, width, height)

	/* ----------------- SHADER INIT ---------------- */
	vertexShaderSource := #load("./shaders/shader.vert")
	fragmentShaderSource := #load("./shaders/shader.frag")
	yellowFragShaderSource := #load("./shaders/yellow.frag")

	vertexShader, success, err_msg := compile_shader(vertexShaderSource, gl.VERTEX_SHADER)
	if (success == i32(gl.FALSE)) {
		fmt.eprintf("ERROR::SHADER::VERTEX::COMPILATION_FAILED %s\n", err_msg)
		return
	}
	fmt.println("[DEBUG] Vertex Shader Compilation Done")

	fragmentShader: u32 // declaring framentShader
	fragmentShader, success, err_msg = compile_shader(fragmentShaderSource, gl.FRAGMENT_SHADER)
	if (success == i32(gl.FALSE)) {
		fmt.eprintf("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED %s\n", err_msg)
		return
	}
	fmt.println("[DEBUG] Fragment Shader Compilation Done")

	yellowFragShader: u32
	yellowFragShader, success, err_msg = compile_shader(yellowFragShaderSource, gl.FRAGMENT_SHADER)
	if (success == i32(gl.FALSE)) {
		fmt.eprintf("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED %s\n", err_msg)
		return
	}
	fmt.println("[DEBUG] Fragment Shader Compilation Done")

	/* --------------- SHADER PROGRAM ------------------- */
	// Need to linked the compiled shaders to a shader program
	// Then activate the program for rendering so they are used
	// to render our objects
	shaderProgram: u32
	shaderProgram, success = create_shader_program({vertexShader, fragmentShader})


	yellowShaderProgram: u32
	yellowShaderProgram, success = create_shader_program({vertexShader, yellowFragShader})


	/* ---------------- VERTEX DATA INIT ---------------- */


	
	// odinfmt: disable
	/*
	vertices := [4][3]f32{
		{0.5, 0.5, 0.0}, 
		{0.5, -0.5, 0.0}, 
		{-0.5, -0.5, 0.0}, 
		{-0.5, 0.5, 0.0}
	}
	*/

	/* Trapezoid but in array buffer VBO
	vertices := [9][3]f32 {
		{0.0, 0.5, 0.0},
		{0.25, 0.0, 0.0}, {-0.25, 0.0, 0.0},
		{0.5, 0.5, 0.0}, // Tip of rightmost triangle 2
		{0.75, 0.0, 0.0}, // bottom right of triangle 2
		{0.25, 0.0, 0.0}, // bottom left of triangle 2
		{0.25, 0.0, 0.0}, // top of inverted triangle 3
		{0.0, 0.5, 0.0},
		{0.5, 0.5, 0.0}
	}
	*/

	verticesT1 := [3][6]f32 {
		{0.0, 0.5, 0.0, 1.0, 0.0, 0.0},
		{0.25, 0.0, 0.0, 0.0, 1.0, 0.0},
		{-0.25, 0.0, 0.0, 0.0, 0.0, 1.0}
	}
	
	verticesT2 := [3][3]f32 {
		{0.5, 0.5, 0.0}, // Tip of rightmost triangle
		{0.75, 0.0, 0.0}, // bottom right of triangle 2
		{0.25, 0.0, 0.0}, // bottom left of triangle 2
	}

	/* Trap Using EBO */
	vertices := [5][3] f32{
		{0.0, 0.5, 0.0},
		{0.25, 0.0, 0.0},
		{-0.25, 0.0, 0.0},
		{0.5, 0.5, 0.0},
		{0.75, 0.0, 0.0},
	}

	/* Two triangle */
	/*
	indices := [6]u32{
		0, 1, 3, // First Triangle
		1, 2, 3, // Second Triangle
	}
	*/
	
	/* Trapezoid Indices */
	indices := [9]u32 {
		0, 1, 2,
		1, 3, 4,
		0, 1, 3
	}

	// odinfmt: enable


	// Defining Vertex Buffer Object
	// Assigning the unique id to the VBO variable via GenBuffers function
	// call
	//VAO, VBO, EBO: u32
	VAO, VBO, EBO: [2]u32 // multi-pointer

	// Casting fixed array to temp slice then raw_data to make it a multi-ptr
	gl.GenVertexArrays(2, raw_data(VAO[:]))
	gl.GenBuffers(2, raw_data(VBO[:]))
	gl.GenBuffers(2, raw_data(EBO[:]))

	// 1. Bind VAO
	gl.BindVertexArray(VAO[0])

	// 2. Copy and Bind VBO
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO[0])
	gl.BufferData(gl.ARRAY_BUFFER, size_of(verticesT1), raw_data(verticesT1[:]), gl.STATIC_DRAW)

	// Same thing for an element buffer object (EBO)
	// TODO if this flips its shit its because I tried to element draw with current
	// set up where I'm using two separate buffers as an exercise
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO[0])
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), raw_data(indices[:]), gl.STATIC_DRAW)

	// 3. Set Vertext Attribute Pointer
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), uintptr(0))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)

	boundBuffer: i32
	gl.GetVertexAttribiv(0, gl.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, &boundBuffer)
	fmt.printf("Bound to VAO0 buffer is: %d\n", boundBuffer)

	/* Do the second triangle in the second VAO (doing two separate buffers) 
		just because for learning purposes
	*/
	gl.BindVertexArray(VAO[1])
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO[1])

	gl.GetIntegerv(gl.ARRAY_BUFFER_BINDING, &boundBuffer)
	fmt.printf("Bound to Array buffer is: %d\n", boundBuffer)


	fmt.println(VBO[1])
	gl.BufferData(gl.ARRAY_BUFFER, size_of(verticesT2), raw_data(verticesT2[:]), gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	// THIS ENABLES THE POINTER IN THE VAO the VAO itself doesn't need enabled
	gl.EnableVertexAttribArray(0)

	gl.GetVertexAttribiv(0, gl.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, &boundBuffer)
	fmt.printf("Bound to VAO1 buffer is: %d\n", boundBuffer)

	// Unbinding from ARRAY_BUFFER can do this since VAO is already tracking
	// the VBO
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	// could unbind the VAO but just am not doing it. To do it gl.BindVertexArray(0)
	gl.BindVertexArray(0)

	// DO NOT UNBIND EBO while VAO is active
	// Unbinding VAO while EBO is bound allow for that binding reference to
	// stay with the VAO and keep being reused. It will be overwritten if
	// something else is bound to gl.ELEMENT_ARRAY_BUFFER while the VAO is active
	// as such only bind EBO is you want to affect the EBO of the currently bound VAO
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)

	fmt.println("[DEBUG] All VAO and VBO init and binding done")


	// Wireframe mode uncomment below
	//gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	running := true
	dragging := false
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
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		// Clears the screen using the Clear Color
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// 4. Draw step
		/*  This is just some code to pass a calculated color into frag shader */
		timeValue := sdl.GetTicks() / 1000.0 // Time in seconds
		greenValue := (math.sin(f32(timeValue)) / 2) + 0.5
		vertexColorLoc := gl.GetUniformLocation(
			shaderProgram,
			strings.clone_to_cstring("uniColor"),
		)
		gl.UseProgram(shaderProgram)
		// gl.Uniform4f(vertexColorLoc, 0.0, greenValue, 0.0, 1.0)

		// don't technically need to bind it every time since only one
		gl.BindVertexArray(VAO[0])

		// Don't need to bind EBO here since VAO has EBO stored from earlier
		// and has not been overwritten by another binding while active
		// gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO[0])

		// primitive type, starting index of vertex array, how many vertices
		// Drawing using VBO + VAO
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		gl.UseProgram(yellowShaderProgram)
		// Draw next VertexArray
		gl.BindVertexArray(VAO[1])
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		// Drawing using indices in EBO, Data in VBO and VAO
		// unsigned int here is u32 I had uint so it wouldn't run
		// gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
		gl.BindVertexArray(0) // could unbind it every time

		sdl.GL_SwapWindow(window)

		mouseX, mouseY: f32
		buttonState := sdl.GetGlobalMouseState(&mouseX, &mouseY)

		normalizedX := normalize_global_coordinate(mouseX, 0, f32(width))

		// Have to invert the Y
		normalizedY := normalize_global_coordinate(mouseY, 0, f32(height)) * -1

		fmt.printf("Normalized X: %f\n NormalizedY: %f\n", normalizedX, normalizedY)
		leftPressed := sdl.MouseButtonFlags.LEFT in buttonState
		fmt.printf("Left Mouse Btn Down: %t\n", leftPressed)

		// BROKEN FOR NOW SINCE I WENT FROM [3][3] to [3][6]
		// Need to make code more maliable
		// Check if shape is "grabbed"
		//		if (leftPressed) {
		//			fmt.printf(
		//				"Cursor inside: %t\n",
		//				is_inside(Point2d{normalizedX, normalizedY}, verticesT1),
		//			)
		//
		//			if (is_inside(Point2d{normalizedX, normalizedY}, verticesT1)) {
		//				dragging = true
		//			}
		//
		//			// follow cursor
		//			// put triangle in center of cursor
		//			// calculate new vertices based on normalized mouse cords
		//			if (dragging) {
		//							// odinfmt: disable
		//				verticesT1 = [3][3]f32{
		//					{0.0+normalizedX, 0.5+normalizedY, 0.0},
		//					{0.25+normalizedX, 0.0+normalizedY, 0.0},
		//					{-0.25+normalizedX, 0.0+normalizedY, 0.0}
		//				}
		//				// odinfmt: enable
		//				gl.BindBuffer(gl.ARRAY_BUFFER, VBO[0])
		//				gl.BufferData(
		//					gl.ARRAY_BUFFER,
		//					size_of(verticesT1),
		//					raw_data(verticesT1[:]),
		//					gl.DYNAMIC_DRAW,
		//				)
		//			}
		//		} else {
		//			dragging = false
		//			// drop
		//		}

		gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	}

	// Clean up
	gl.DeleteVertexArrays(2, raw_data(VAO[:]))
	gl.DeleteBuffers(2, raw_data(VBO[:]))
	gl.DeleteProgram(shaderProgram)

	sdl.Quit()
	return
}
