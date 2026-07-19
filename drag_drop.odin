package main

import "core:fmt"

Point2d :: struct {
	x: f32,
	y: f32,
}


normalize_global_coordinate :: proc(n, min, max: f32) -> f32 {
	return 2 * ((n - min) / max - min) - 1
}


/*
	Only doing triangles for now.
	// TODO allow for any number for slices assume every vertex
	// to vertex combo is a edge
	// make an overload to accept indicies to target what the edges are 
*/
is_inside :: proc(p: Point2d, vertices: [3][3]f32) -> bool {
	// Use the Ray Casting Algorithm with the vertice cordinates
	// If element arrays will need to determine the individula triangle
	// based on indices + verties. For just Array buffer drawing
	// just the vertices will do
	intersect := false

	fmt.printf("V1 X: %f\n V1 Y: %f\n", vertices[0][0], vertices[0][1])

	// How many pairs 6 / 2 = 3 because 1 extra per vertex
	// (v1, v2), (v1, v3), (v2, v3) not sure how to loop through these cleanly
	// so for now going to check each edge by hand
	if (does_intersect(p, {vertices[0], vertices[1]})) {
		intersect = !intersect
	}

	if (does_intersect(p, {vertices[0], vertices[2]})) {
		intersect = !intersect
	}

	if (does_intersect(p, {vertices[1], vertices[2]})) {
		intersect = !intersect
	}

	return intersect
}

does_intersect :: proc(p: Point2d, edge: [2][3]f32) -> bool {
	// Can use linear interpolation formula (rearraged point-slope formula)
	// to figure out were x-interp would be on the edge if y = yp
	// then if xp < x-interp then xp ( this is due to raycasting to right)
	// if we wanted to ray cast to left then xp > x-interp
	// x < (x2 - x1) * (yp - y1) / (y2 - y1) + x1 << point-slope
	return(
		(edge[0][1] > p.y) != ((edge[1][1] > p.y)) &&
		(p.x <
				((edge[1][0] - edge[0][0]) * (p.y - edge[0][1]) / (edge[1][1] - edge[0][1]) +
						edge[0][0])) \
	)
}
