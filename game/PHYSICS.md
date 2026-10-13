# How the car sim works

`sim/car_sim.gd` is a single-track ("bicycle") model stepped twelve times a frame, with a real
engine, clutch, gearbox and one driven shaft.

- **Loads.** Static weight split from `cg_front`/`wheelbase`, plus weight transfer from the last
  longitudinal and lateral accelerations (lagged a few tenths of a second), plus downforce
  (`cl`) that grows with speed squared.
- **Grip.** Each tire's grip is surface x compound x temperature window x tread
  (`tire_mu`). Wider rears (`rear_grip`), limited-slip gain (`lsd`) and compound quirks
  (`launch`, `lateral`) scale the axles.
- **Driven axles.** `drivetrain` picks them: FWD drives the front, RWD the rear, AWD both through
  a locked centre. A driven tire uses combined slip: the slip vector (wheelspin, slip angle)
  goes through one Pacejka-style curve and the force points along it, so wheelspin eats side
  grip. That gives power oversteer on rear-drivers and power understeer on front-drivers.
  The handbrake locks the rear; on AWD it splits the rear off the centre so you can still throw
  the car into a slide.
- **Free axles** roll and brake up to their grip; past it they lock (SIM) or ABS holds them just
  under (STREET, ARCADE). ABS also eases the brakes on the driven shaft before it locks.
- **Engine.** Torque curve x boost (turbo spool with lag) x health, minus friction and pumping
  losses (engine braking off the gas). The auto-clutch slips on launch and opens on shifts; the
  auto gearbox shifts on road speed so wheelspin doesn't make it hunt.
- **Steering.** Lock shrinks with speed, but steering into a slide may go past that, up to the
  slide angle, so a stick can catch a drift. The wheel turns quickly at parking speed, calmer at
  speed, and returns to centre faster than it turns in.
- **Assists** (in `world/player_car.gd`): STREET and ARCADE add traction control on the driven
  wheels (`drive_slip()`), a little stability help, and less lock at speed. SIM adds nothing.
- **Wear and heat.** Tires wear and heat with sliding power; brakes heat and fade
  (`brakes.fade_c`); the engine takes damage from over-revving, cold revving and overheating.

Knobs most worth turning per car: `steer_lock`, `rear_grip`, `lsd`, `brakes.bias`,
`tires.compound`, `cg_front`, `cg_height`. Tests: `tests/run_tests.gd`, `tests/physics_tests.gd`.
