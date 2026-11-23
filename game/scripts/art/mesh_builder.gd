class_name MeshBuilder
extends RefCounted
## Flat-shaded, vertex-coloured geometry. All shipped meshes are built this way:
## no textures, no normal maps, confident silhouettes, cheap on iPhone.

var verts := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var xform := Transform3D.IDENTITY


func set_transform(t: Transform3D) -> void:
	xform = t


func reset_transform() -> void:
	xform = Transform3D.IDENTITY


func _p(v: Vector3) -> Vector3:
	return xform * v


func add_triangle(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var pa := _p(a)
	var pb := _p(b)
	var pc := _p(c)
	var n := (pb - pa).cross(pc - pa).normalized()
	if n.length_squared() < 0.000001:
		return
	for p in [pa, pb, pc]:
		verts.append(p)
		normals.append(n)
		colors.append(color)


func add_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	add_triangle(a, b, c, color)
	add_triangle(a, c, d, color)


func add_box(size: Vector3, color: Color, center: Vector3 = Vector3.ZERO) -> void:
	var h := size * 0.5
	var p := [
		center + Vector3(-h.x, -h.y, h.z), center + Vector3(h.x, -h.y, h.z),
		center + Vector3(h.x, h.y, h.z), center + Vector3(-h.x, h.y, h.z),
		center + Vector3(-h.x, -h.y, -h.z), center + Vector3(h.x, -h.y, -h.z),
		center + Vector3(h.x, h.y, -h.z), center + Vector3(-h.x, h.y, -h.z),
	]
	var dark := color.darkened(0.12)
	add_quad(p[0], p[1], p[2], p[3], color) # front (+z)
	add_quad(p[5], p[4], p[7], p[6], color.darkened(0.08)) # back
	add_quad(p[1], p[5], p[6], p[2], dark) # right
	add_quad(p[4], p[0], p[3], p[7], dark) # left
	add_quad(p[3], p[2], p[6], p[7], color.lightened(0.08)) # top
	add_quad(p[4], p[5], p[1], p[0], color.darkened(0.18)) # bottom


func add_cylinder(radius: float, height: float, segments: int, color: Color, center: Vector3 = Vector3.ZERO, top_radius: float = -1.0) -> void:
	if top_radius < 0.0:
		top_radius = radius
	var seg := maxi(3, segments)
	var half := height * 0.5
	for i in seg:
		var a0 := TAU * float(i) / seg
		var a1 := TAU * float(i + 1) / seg
		var b0 := center + Vector3(cos(a0) * radius, -half, sin(a0) * radius)
		var b1 := center + Vector3(cos(a1) * radius, -half, sin(a1) * radius)
		var t0 := center + Vector3(cos(a0) * top_radius, half, sin(a0) * top_radius)
		var t1 := center + Vector3(cos(a1) * top_radius, half, sin(a1) * top_radius)
		add_quad(b0, b1, t1, t0, color)
	for i in seg:
		var a0 := TAU * float(i) / seg
		var a1 := TAU * float(i + 1) / seg
		var t0 := center + Vector3(cos(a0) * top_radius, half, sin(a0) * top_radius)
		var t1 := center + Vector3(cos(a1) * top_radius, half, sin(a1) * top_radius)
		add_triangle(center + Vector3(0, half, 0), t0, t1, color.lightened(0.08))
		var b0 := center + Vector3(cos(a0) * radius, -half, sin(a0) * radius)
		var b1 := center + Vector3(cos(a1) * radius, -half, sin(a1) * radius)
		add_triangle(center + Vector3(0, -half, 0), b1, b0, color.darkened(0.15))


func add_cone(radius: float, height: float, segments: int, color: Color, center: Vector3 = Vector3.ZERO) -> void:
	add_cylinder(radius, height, segments, color, center, 0.02)


func add_sphere(radius: float, segments: int, rings: int, color: Color, center: Vector3 = Vector3.ZERO) -> void:
	var seg := maxi(4, segments)
	var ring := maxi(2, rings)
	for r in ring:
		var v0 := PI * float(r) / ring
		var v1 := PI * float(r + 1) / ring
		for s in seg:
			var u0 := TAU * float(s) / seg
			var u1 := TAU * float(s + 1) / seg
			var p00 := center + Vector3(sin(v0) * cos(u0), cos(v0), sin(v0) * sin(u0)) * radius
			var p10 := center + Vector3(sin(v0) * cos(u1), cos(v0), sin(v0) * sin(u1)) * radius
			var p01 := center + Vector3(sin(v1) * cos(u0), cos(v1), sin(v1) * sin(u0)) * radius
			var p11 := center + Vector3(sin(v1) * cos(u1), cos(v1), sin(v1) * sin(u1)) * radius
			add_quad(p00, p10, p11, p01, color)


func add_prism(size: Vector3, color: Color, center: Vector3 = Vector3.ZERO) -> void:
	# A triangular roof prism, ridge along X.
	var h := size * 0.5
	var a := center + Vector3(-h.x, -h.y, -h.z)
	var b := center + Vector3(h.x, -h.y, -h.z)
	var c := center + Vector3(h.x, -h.y, h.z)
	var d := center + Vector3(-h.x, -h.y, h.z)
	var ridge_l := center + Vector3(-h.x, h.y, 0)
	var ridge_r := center + Vector3(h.x, h.y, 0)
	add_quad(a, b, ridge_r, ridge_l, color.darkened(0.1))
	add_quad(c, d, ridge_l, ridge_r, color)
	add_triangle(b, c, ridge_r, color.darkened(0.2))
	add_triangle(d, a, ridge_l, color.darkened(0.2))
	add_quad(a, d, c, b, color.darkened(0.25))


func add_ring(radius: float, thickness: float, segments: int, color: Color, center: Vector3 = Vector3.ZERO, axis: String = "y") -> void:
	var seg := maxi(5, segments)
	for i in seg:
		var a0 := TAU * float(i) / seg
		var a1 := TAU * float(i + 1) / seg
		var r0 := radius - thickness * 0.5
		var r1 := radius + thickness * 0.5
		var p0: Vector3
		var p1: Vector3
		var p2: Vector3
		var p3: Vector3
		if axis == "y":
			p0 = center + Vector3(cos(a0) * r0, 0, sin(a0) * r0)
			p1 = center + Vector3(cos(a0) * r1, 0, sin(a0) * r1)
			p2 = center + Vector3(cos(a1) * r1, 0, sin(a1) * r1)
			p3 = center + Vector3(cos(a1) * r0, 0, sin(a1) * r0)
		elif axis == "z":
			p0 = center + Vector3(cos(a0) * r0, sin(a0) * r0, 0)
			p1 = center + Vector3(cos(a0) * r1, sin(a0) * r1, 0)
			p2 = center + Vector3(cos(a1) * r1, sin(a1) * r1, 0)
			p3 = center + Vector3(cos(a1) * r0, sin(a1) * r0, 0)
		else:
			p0 = center + Vector3(0, cos(a0) * r0, sin(a0) * r0)
			p1 = center + Vector3(0, cos(a0) * r1, sin(a0) * r1)
			p2 = center + Vector3(0, cos(a1) * r1, sin(a1) * r1)
			p3 = center + Vector3(0, cos(a1) * r0, sin(a1) * r0)
		add_quad(p0, p1, p2, p3, color)


func add_line(a: Vector3, b: Vector3, width: float, color: Color) -> void:
	var dir := (b - a).normalized()
	var side := dir.cross(Vector3.UP).normalized() * width * 0.5
	if side.length_squared() < 0.0001:
		side = dir.cross(Vector3.RIGHT).normalized() * width * 0.5
	add_quad(a - side, a + side, b + side, b - side, color)


func commit(material: Material = null) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in verts.size():
		st.set_normal(normals[i])
		st.set_color(colors[i])
		st.add_vertex(verts[i])
	var mesh := st.commit()
	if material != null:
		mesh.surface_set_material(0, material)
	return mesh
