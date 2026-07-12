package main

import "core:fmt"
import "core:os"
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

	vertices := []f32{-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0}


	/*---------------- VERTEX INPUT ----------------------------- */

	// Defining Vertex Buffer Object
	// Assigning the unique id to the VBO variable via GenBuffers function
	// call
	VBO: u32
	gl.GenBuffers(1, &VBO)
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)

	// Feeding data in whatever buffer is currently plugged in to the ARRAY_BUFFER
	// via bind buffer. STATIC_DRAW sets the data once and is used many times
	// Other types
	// STREAM_DRAW if that data is set once and only used a few times
	// DYNAMIC_DRAW data changes a lot and used a lot
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(vertices), gl.STATIC_DRAW)

	/* -------------------- VERTEX SHADER ------------------------ */
	// Need to write in GLSL OpenGL Shading Language
	// Might want to write this in a separte shader.vert file
	// and load it on compile time

	// This will do for now but for readability sake might be better to do something
	// different
	// Need to read more about GLSL
	vertexShaderCodeSource :=
		`#version 330 core
layout (location = 0) in vec3 aPos;
void main()
{
	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}` +
		"\x00"

	vertexShaderSource: cstring = cstring(raw_data(vertexShaderCodeSource))

	/* ----------------- SHADER COMPILATION --------------------- */
	// define a shader object based on what the type of shader
	// we want it to be at run time
	vertexShader := gl.CreateShader(gl.VERTEX_SHADER)

	// pass the shader, the number of strings in the array, array of pointers
	// to strings (in my case it is just one string no array), array of all
	// of the string lengths that the pointers are pointing to
	gl.ShaderSource(vertexShader, 1, &vertexShaderSource, nil)
	gl.CompileShader(vertexShader)

	success: i32
	infoLog: [512]u8 // Remember char is just 8-bit unsigned int

	gl.GetShaderiv(vertexShader, gl.COMPILE_STATUS, &success)

	// If shader failed taking a guess that 0 is false since success is i32
	if (success == i32(gl.FALSE)) {
		gl.GetShaderInfoLog(vertexShader, 512, nil, raw_data(infoLog[:]))

		// Find num bytes before terminal
		bytes_read, _ := os.read(os.stdin, infoLog[:])
		err_msg := string(infoLog[0:bytes_read])
		fmt.eprintf("ERROR::SHADER::VERTEX::COMPILATION_FAILED %s\n", err_msg)
		return
	}

	/* ------------------- FRAGMENT SHADER ----------------- */

	fragmentShaderCodeSource :=
		`#version 330 core
out vec4 FragColor;
void main()
{
	FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}` +
		"\x00"

	fragmentShaderSource: cstring = cstring(raw_data(fragmentShaderCodeSource))
	fragmentShader := gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fragmentShader, 1, &fragmentShaderSource, nil)
	gl.CompileShader(fragmentShader)

	gl.GetShaderiv(fragmentShader, gl.COMPILE_STATUS, &success)

	if (success == i32(gl.FALSE)) {
		gl.GetShaderInfoLog(fragmentShader, 512, nil, raw_data(infoLog[:]))

		bytes_read, _ := os.read(os.stdin, infoLog[:])
		err_msg := string(infoLog[0:bytes_read])
		fmt.eprintf("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED %s\n", err_msg)
		return
	}

	/* --------------- SHADER PROGRAM ------------------- */
	// Need to linked the compiled shaders to a shader program
	// Then activate the program for rendering so they are used
	// to render our objects

	// Returns id to new program
	shaderProgram := gl.CreateProgram()

	gl.AttachShader(shaderProgram, vertexShader)
	gl.AttachShader(shaderProgram, fragmentShader)
	gl.LinkProgram(shaderProgram)

	gl.GetProgramiv(shaderProgram, gl.LINK_STATUS, &success)

	if (success == i32(gl.FALSE)) {
		gl.GetProgramInfoLog(shaderProgram, 512, nil, raw_data(infoLog[:]))

		bytes_read, _ := os.read(os.stdin, infoLog[:])
		err_msg := string(infoLog[0:bytes_read])
		fmt.eprintf("ERROR::PROGRAM::SHADER::LINKING_FAILED %s\n", err_msg)
		return
	}

	gl.UseProgram(shaderProgram)

	// Don't need this objects any more since they are linked to the program
	gl.DeleteShader(vertexShader)
	gl.DeleteShader(fragmentShader)

	/* ---------------- LINKING VERTEX ATTRIBUTES ---------------- */
	// First Argument: Specified the location of the postition vertex attribute at 0 in
	// in the vertex shader.
	// Second Argument: Vec3 so has 3 values
	// Third Argument is type which is f32 as vec* in GLSL is floats
	// Fourth Argument don't need it normalized since we are using float 0 through 1
	// Fifth Argument is the size of each vertex "stride" 3 * sizeof(float)
	// Sixth is the offset void * which in odin uintptr
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))

	// NOTES ON ABOVE each vertex attributes take its data from the memory managed
	// by a VBO (can have multiple). The VBO it takes from is whatever VBO is bound
	// to the gl.ARRAY_BUFFER at the time.
	// I.e. since out original VBO should be still bound vertex attribute 0
	// the pointer we created about should associated with our VBO that we had
	// bound (socketed)

	// This is the rough drawing process in order assuming the shader
	// program was built ahead of time
	/* 
		// 1. copy vertices array to buffer for openGL
		gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
		gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), vertices, gl.STATIC_DRAW)

		// 2. set the vertex attribute pointers
		gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))

		// 3. use the shaderProgram to render the object
		gl.UseProgram(shaderProgram)

		// 4. Draw the object
		// someOpenGLProgramToDraw
	*/

	/* ------------------ Vertex Array Object --------------------- */
	// Expanding on the above
	// We need to setup a VAO much like a VBO earlier since OpenGL will refuse
	// to draw without a VAO.
	// VAO can be bound like any vertex buffer and stores the vertex attribute
	// pointer calls so those calls only need to be made once and if we
	// want to use them we just bind the VAO or swap it for another one that
	// had a different set of pointer bound. REMEMBER STATE MACHINE

	// Going to redo some of the stuff above since the order changes with this
	// knowledge VAO bind frist then bind VBO then set Attribute Pointer and enable
	// it

	// PRETTY much 1-3 is initialization
	VAO: u32
	gl.GenVertexArrays(1, &VAO)

	// 1. Bind VAO
	gl.BindVertexArray(VAO)

	// 2. Copy and Bind VBO
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(vertices), gl.STATIC_DRAW)

	// 3. Set Vertext Attribute Pointer
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(0)

	// 4. Draw - NON-INITIALIZATION STEP choose shader program and VAO to draw
	// Moved to inside of the for loop


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

		// 4. Draw step
		gl.UseProgram(shaderProgram)

		// don't technically need to bind it every time since only one
		gl.BindVertexArray(VAO)

		// primitive type, starting index of vertex array, how many vertices
		gl.DrawArrays(gl.TRIANGLES, 0, 3)
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
