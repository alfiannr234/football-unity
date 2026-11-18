class_name SlingshotPhysics
extends RefCounted

# Pure deterministic 3D slingshot & Magnus curve physics engine for Football Unity.
# Decoupled from SceneTree so both MatchScene (3D) and headless tests can evaluate identical trajectories.

const GRAVITY := 9.81
const BALL_RADIUS := 0.115
const AIR_DRAG := 0.18
const GRASS_RESTITUTION := 0.56
const GRASS_FRICTION := 0.84

# Standard FIFA goal dimensions centered at z = -52.5 (top goal) or z = +52.5 (bottom goal)
const PITCH_HALF_W := 34.0
const PITCH_HALF_L := 52.5
const GOAL_HALF_W := 3.66
const GOAL_HEIGHT := 2.44
const GOAL_DEPTH := 2.2
const POST_RADIUS := 0.08

static func compute_launch_params(
	drag_screen_delta: Vector2,
	max_drag_px: float,
	kekuatan: int,
	akurasi: int,
	efek: int,
	penalti: int,
	bola_mati: int,
	spin_offset: Vector2,
	is_penalty: bool = false,
	is_free_kick: bool = false,
	difficulty_spread_mult: float = 1.0,
	apply_random_spread: bool = false
) -> Dictionary:
	# drag_screen_delta is (start - current) so pulling down/back shoots forward (+target)!
	var mag := clampf(drag_screen_delta.length() / maxf(max_drag_px, 1.0), 0.0, 1.0)
	var dir_2d := drag_screen_delta.normalized() if drag_screen_delta.length() > 2.0 else Vector2(0, -1)

	# Speed scaled by Kekuatan (60 -> ~27 m/s, 99 -> ~36 m/s)
	var max_speed := lerpf(21.0, 36.5, clampf(float(kekuatan) / 99.0, 0.2, 1.0))
	var speed := lerpf(7.5, max_speed, mag)

	# Vertical loft angle (radians): pulling harder gives higher loft up to ~25 deg, moderated by spin_offset.y
	var base_loft := lerpf(0.08, 0.38, mag)
	if is_penalty:
		base_loft = lerpf(0.05, 0.26, mag)
	elif is_free_kick:
		base_loft = lerpf(0.16, 0.44, mag)
	var loft := clampf(base_loft - spin_offset.y * 0.12, 0.03, 0.52)

	# Convert 2D aim (x right, y up on screen -> -Z on pitch) into 3D horizontal direction
	# When user pulls DOWN on screen (start.y < current.y), drag_screen_delta = start - current has y < 0 (aiming UP / -Z)
	var horiz := Vector3(dir_2d.x, 0.0, dir_2d.y).normalized()
	if horiz.length() < 0.001:
		horiz = Vector3(0.0, 0.0, -1.0)

	# Apply accuracy/specialty angular spread if requested (used on actual release, NOT preview!)
	var relevant_acc := float(akurasi)
	if is_penalty:
		relevant_acc = float(akurasi) * 0.4 + float(penalti) * 0.6
	elif is_free_kick:
		relevant_acc = float(akurasi) * 0.5 + float(bola_mati) * 0.5

	var spread_deg := lerpf(7.5, 0.45, clampf(relevant_acc / 99.0, 0.0, 1.0)) * difficulty_spread_mult
	if apply_random_spread and mag > 0.05:
		var yaw_err := deg_to_rad(randf_range(-spread_deg, spread_deg))
		horiz = horiz.rotated(Vector3.UP, yaw_err)
		loft = clampf(loft + deg_to_rad(randf_range(-spread_deg * 0.4, spread_deg * 0.4)), 0.02, 0.56)

	var v_horiz := speed * cos(loft)
	var v_vert := speed * sin(loft)
	var velocity := Vector3(horiz.x * v_horiz, v_vert, horiz.z * v_horiz)

	# Magnus spin vector omega (rad/s): lateral spin_offset.x curves left/right
	var curve_scale := lerpf(5.5, 19.5, clampf(float(efek) / 99.0, 0.0, 1.0))
	var omega := Vector3(spin_offset.y * curve_scale * 0.4, -spin_offset.x * curve_scale, 0.0)

	return {
		"power_ratio": mag,
		"velocity": velocity,
		"omega": omega,
		"spread_deg": spread_deg,
		"loft_deg": rad_to_deg(loft),
		"speed": speed,
	}

static func step_ball(
	pos: Vector3,
	vel: Vector3,
	omega: Vector3,
	efek: int,
	dt: float
) -> Dictionary:
	# Magnus Force: F_magnus = S(Efek) * (omega x vel)
	var magnus_coeff := lerpf(0.018, 0.052, clampf(float(efek) / 99.0, 0.0, 1.0))
	var magnus_acc := omega.cross(vel) * magnus_coeff
	var drag_acc := -vel * (AIR_DRAG * (0.4 + 0.02 * vel.length()))

	var acc := Vector3(0.0, -GRAVITY, 0.0) + magnus_acc + drag_acc
	var next_vel := vel + acc * dt
	var next_pos := pos + next_vel * dt
	var hit_event := ""

	# Ground bounce
	if next_pos.y < BALL_RADIUS:
		next_pos.y = BALL_RADIUS
		if absf(next_vel.y) > 0.9:
			next_vel.y = -next_vel.y * GRASS_RESTITUTION
			next_vel.x *= GRASS_FRICTION
			next_vel.z *= GRASS_FRICTION
			omega *= 0.85
			hit_event = "bounce"
		else:
			next_vel.y = 0.0
			next_vel.x *= (1.0 - 1.6 * dt)
			next_vel.z *= (1.0 - 1.6 * dt)
			omega *= (1.0 - 2.0 * dt)

	# Top Goal Frame & Net Check (z <= -PITCH_HALF_L) using exact plane-crossing interpolation (no tunneling!)
	var goal_z := -PITCH_HALF_L
	if pos.z >= goal_z and next_pos.z <= goal_z + BALL_RADIUS:
		var dz := next_pos.z - pos.z
		var t_cross := clampf((goal_z - pos.z) / dz, 0.0, 1.0) if absf(dz) > 0.0001 else 1.0
		var cross_x := lerpf(pos.x, next_pos.x, t_cross)
		var cross_y := lerpf(pos.y, next_pos.y, t_cross)
		var hit_r := BALL_RADIUS + POST_RADIUS

		var hit_left_post := absf(cross_x - (-GOAL_HALF_W)) <= hit_r and cross_y <= GOAL_HEIGHT + hit_r
		var hit_right_post := absf(cross_x - GOAL_HALF_W) <= hit_r and cross_y <= GOAL_HEIGHT + hit_r
		var hit_crossbar := absf(cross_x) <= GOAL_HALF_W + hit_r and absf(cross_y - GOAL_HEIGHT) <= hit_r

		if hit_left_post or hit_right_post or hit_crossbar:
			next_vel.z = absf(next_vel.z) * 0.65
			if hit_left_post:
				next_vel.x += 3.5
			elif hit_right_post:
				next_vel.x -= 3.5
			if hit_crossbar:
				next_vel.y = absf(next_vel.y) * 0.55
			next_pos.z = goal_z + BALL_RADIUS + 0.05
			hit_event = "post"
		elif next_pos.z <= goal_z and absf(cross_x) < GOAL_HALF_W - BALL_RADIUS * 0.3 and cross_y < GOAL_HEIGHT - BALL_RADIUS * 0.3:
			hit_event = "goal"

	# Inside goal net damping (once past goal line within goal frame)
	if next_pos.z < goal_z and absf(next_pos.x) <= GOAL_HALF_W and next_pos.y <= GOAL_HEIGHT:
		if next_pos.z < goal_z - GOAL_DEPTH + BALL_RADIUS:
			next_pos.z = goal_z - GOAL_DEPTH + BALL_RADIUS
			next_vel.z = absf(next_vel.z) * 0.15
			next_vel.x *= 0.45
			next_vel.y *= 0.45
		if absf(next_pos.x) > GOAL_HALF_W - BALL_RADIUS:
			next_pos.x = signf(next_pos.x) * (GOAL_HALF_W - BALL_RADIUS)
			next_vel.x *= -0.25

	return {
		"pos": next_pos,
		"vel": next_vel,
		"omega": omega,
		"hit": hit_event,
	}

static func predict_trajectory(
	start_pos: Vector3,
	velocity: Vector3,
	omega: Vector3,
	efek: int,
	max_steps: int = 36,
	dt: float = 0.035
) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var p := start_pos
	var v := velocity
	var w := omega
	pts.append(p)
	for _i in range(max_steps):
		var res := step_ball(p, v, w, efek, dt)
		p = res["pos"]
		v = res["vel"]
		w = res["omega"]
		pts.append(p)
		if p.z < -PITCH_HALF_L - 0.8:
			break
	return pts
