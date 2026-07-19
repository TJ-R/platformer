package main
import "core:fmt"
import "core:os"
import gl "vendor:OpenGL"

Shader :: struct {
	// Program ID
	ID: u32,
}


// "Constructor"
init_shader :: proc(shader: ^Shader, vertexPath, fragmentPath: string) {
	vertexSrc, err := os.read_entire_file_from_path(vertexPath, context.allocator)
	if err != nil {
		fmt.printf("Error reading vertex shader.\n%d\n", err)
		return
	}

	v_id, ok, err_msg := compile_shader(vertexSrc, gl.VERTEX_SHADER)
	if (ok == i32(gl.FALSE)) {
		fmt.eprintf("ERROR::SHADER::VERTEX::COMPILATION_FAILED %s\n", err_msg)
		return
	}
	fmt.println("[DEBUG] Vertex Shader Compilation Done")


	fragSrc: []byte
	fragSrc, err = os.read_entire_file_from_path(fragmentPath, context.allocator)
	if err != nil {
		fmt.printf("Error reading vertex shader.\n%d\n", err)
		return
	}

	f_id: u32
	f_id, ok, err_msg = compile_shader(fragSrc, gl.FRAGMENT_SHADER)
	if (ok == i32(gl.FALSE)) {
		fmt.eprintf("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED %s\n", err_msg)
		return
	}
	fmt.println("[DEBUG] Fragment Shader Compilation Done")

	p_id: u32
	p_id, ok = create_shader_program({v_id, f_id})
	if (ok == i32(gl.FALSE)) {
		fmt.eprintf("ERROR::SHADER::PROGRAM::CREATION_FAILED %s\n", err_msg)
		return
	}
	fmt.println("[DEBUG] Shader Program Created")

	shader.ID = p_id
}

/* Function to use the shader */
use_shader :: proc(shader: ^Shader) {
	gl.UseProgram(shader.ID)
}

/* Functions to set value for shader (uniform values) */
shader_set_bool :: proc(shader: ^Shader, name: string, val: bool) {}
shader_set_int :: proc(shader: ^Shader, name: string, val: bool) {}
shader_set_float :: proc(shader: ^Shader, name: string, val: bool) {}

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
