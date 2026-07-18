package main

import "core:fmt"
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

	// Have to load the proc address to call gl funcdtions
	gl.load_up_to(3, 3, sdl.gl_set_proc_address)
	gl.Viewport(0, 0, 1280, 720)

	/* ----------------- SHADER INIT ---------------- */
	vertexShaderSource := #load("./shaders/shader.vert")
	fragmentShaderSource := #load("./shaders/shader.frag")

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

	/* --------------- SHADER PROGRAM ------------------- */
	// Need to linked the compiled shaders to a shader program
	// Then activate the program for rendering so they are used
	// to render our objects
	shaderProgram: u32
	shaderProgram, success = create_shader_program({vertexShader, fragmentShader})

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
		{0.25, 0.0, 0.0},
		{-0.25, 0.0, 0.0},
		{0.5, 0.5, 0.0}, // Tip of rightmost triangle
		{0.75, 0.0, 0.0}, // bottom right of triangle 2
		{0.25, 0.0, 0.0}, // bottom left of triangle 2
		{0.25, 0.0, 0.0}, // top of inverted triangle 3
		{0.0, 0.5, 0.0},
		{0.5, 0.5, 0.0}
	}
	*/


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
	VBO, VAO, EBO: u32
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.GenBuffers(1, &EBO)

	// 1. Bind VAO
	gl.BindVertexArray(VAO)

	// 2. Copy and Bind VBO
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)

	// Same thing for an element buffer object (EBO)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), raw_data(indices[:]), gl.STATIC_DRAW)

	// 3. Set Vertext Attribute Pointer
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

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
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

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
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		// Clears the screen using the Clear Color
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// 4. Draw step
		gl.UseProgram(shaderProgram)

		// don't technically need to bind it every time since only one
		gl.BindVertexArray(VAO)

		// Don't need to bind EBO here since VAO has EBO stored from earlier
		// and has not been overwritten by another binding while active
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)

		// primitive type, starting index of vertex array, how many vertices
		// Drawing using VBO + VAO
		// gl.DrawArrays(gl.TRIANGLES, 0, 9)

		// Drawing using indices in EBO, Data in VBO and VAO
		// unsigned int here is u32 I had uint so it wouldn't run
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

		// gl.BindVertexArray(0) // could unbind it every time

		sdl.GL_SwapWindow(window)

	}

	// Clean up
	gl.DeleteVertexArrays(1, &VAO)
	gl.DeleteBuffers(1, &VBO)
	gl.DeleteProgram(shaderProgram)

	sdl.Quit()
	return
}

compile_shader :: proc(src: []byte, shaderType: u32) -> (u32, i32, string) {
	cstr: cstring = cstring(raw_data(src))
	shader := gl.CreateShader(shaderType)

	// pass the shader, the number of strings in the array, array of pointers
	// to strings (in my case it is just one string no array), array of all
	// of the string lengths that the pointers are pointing to
	// PROBABLY SHOULD CHANGE NIL TO LENGTH SINCE THIS PROCEDURE (FUNCTION)
	// IS SUPPOSED TO HANDLE COMPILING ALL KINDS OF DIFFERENT SHADERS
	gl.ShaderSource(shader, 1, &cstr, nil)
	gl.CompileShader(shader)

	success: i32
	infoLog: [512]u8 // Remember char is just 8-bit unsigned int
	logLength: i32

	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)

	// If shader failed taking a guess that 0 is false since success is i32
	if (success == i32(gl.FALSE)) {
		gl.GetShaderInfoLog(shader, 512, &logLength, raw_data(infoLog[:]))
		// Find num bytes before terminal
		err_msg := string(infoLog[:logLength])
		return shader, success, err_msg
	}

	return shader, success, ""
}

create_shader_program :: proc(shaders: []u32) -> (u32, i32) {
	shaderProgram := gl.CreateProgram()

	for shader in shaders {
		gl.AttachShader(shaderProgram, shader)
	}

	gl.LinkProgram(shaderProgram)

	success: i32
	infoLog: [512]u8 // Remember char is just 8-bit unsigned int
	logLength: i32
	gl.GetProgramiv(shaderProgram, gl.LINK_STATUS, &success)

	if (success == i32(gl.FALSE)) {
		gl.GetProgramInfoLog(shaderProgram, 512, &logLength, raw_data(infoLog[:]))

		err_msg := string(infoLog[:logLength])
		fmt.eprintf("ERROR::PROGRAM::SHADER::LINKING_FAILED %s\n", err_msg)
		return shaderProgram, i32(gl.FALSE)
	}
	fmt.println("[DEBUG] Program Shader Linking Done")
	// Don't need this objects any more since they are linked to the program
	for shader in shaders {
		gl.DeleteShader(shader)
	}

	return shaderProgram, i32(gl.TRUE)
}
