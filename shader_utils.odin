package main
import "core:fmt"
import gl "vendor:OpenGL"


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
