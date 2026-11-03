defmodule Goatbot.TUI do
  @moduledoc """
  The robot's `BB.TUI.Extension`: what the bb_tui dashboard adds for it.

  Driving goes through `BB.NSK.Drive`, the same messages `Goatbot.Dashboard`
  and the phone pad send: `↑`/`↓` a full throttle, `←`/`→` a turn at
  `[:yaw, :turn_rate]`. The panels read the lean joint and the three
  controllers' state:

    * **Goatbot** (beside the drive pad) — lean and its horizon, speed,
      target speed, heading.
    * **Balance** — `Goatbot.Balancer`: lean, setpoint, target, the wheel
      command, and a chart of the lean against what it is steered towards.
    * **Velocity** — `Goatbot.VelocityController`: the speed estimate, the
      target speed and its ramp, and the lean offset it asks for.
    * **Yaw** — `Goatbot.YawController`: heading, the heading held, and the
      differential it spends holding it.

  `s` stands the robot up, and a hint per state says what to do next, as
  `Goatbot.Dashboard`'s banner does.

      BB.TUI.run(Goatbot.Robot, extensions: [Goatbot.TUI])
  """

  use BB.TUI.Extension

  # Wheel rad/s to m/s: `Goatbot.VelocityController`'s `wheel_radius`, 21.5 mm.
  @wheel_radius 0.0215

  drive do
    publish {BB.NSK.Drive, :command}
    stop {BB.NSK.Drive, :stop}
    turn_scale param([:yaw, :turn_rate])
  end

  panels do
    panel :driving do
      title "Goatbot"
      tab :drive
      readout "lean", joint(:lean), unit: :degree, decimals: 1, spark: true

      readout "speed", controller(:velocity_hold, :average),
        scale: @wheel_radius,
        unit: :centimeter_per_second,
        decimals: 0

      readout "target", controller(:velocity_hold, :target_speed),
        unit: :centimeter_per_second,
        decimals: 0

      readout "heading", controller(:yaw_hold, :heading), unit: :degree, decimals: 0
      attitude "lean", pitch: joint(:lean), range: 20
    end

    panel :balance do
      title "Balance"
      readout "lean", joint(:lean), unit: :degree, decimals: 1
      readout "setpoint", controller(:pid_balancer, :setpoint), unit: :degree, decimals: 1
      readout "target", controller(:pid_balancer, :target), unit: :degree, decimals: 1
      readout "offset", controller(:pid_balancer, :offset), unit: :degree, decimals: 2

      readout "command", controller(:pid_balancer, :last_command),
        unit: :radian_per_second,
        decimals: 1,
        spark: true

      readout "integral", controller(:pid_balancer, :integral), decimals: 4
      readout "mode", controller(:pid_balancer, :mode)

      plot "lean vs target",
           [
             joint(:lean),
             controller(:pid_balancer, :target),
             controller(:pid_balancer, :setpoint)
           ],
           unit: :degree,
           window: 10_000
    end

    panel :velocity do
      title "Velocity"

      readout "speed", controller(:velocity_hold, :average),
        scale: @wheel_radius,
        unit: :centimeter_per_second,
        decimals: 1,
        spark: true

      readout "target", controller(:velocity_hold, :target_speed),
        unit: :centimeter_per_second,
        decimals: 1

      readout "ramp", controller(:velocity_hold, :speed_ref),
        unit: :centimeter_per_second,
        decimals: 1

      readout "offset", controller(:velocity_hold, :offset), unit: :degree, decimals: 2
      readout "trim", controller(:velocity_hold, :trim), unit: :degree, decimals: 2

      plot "target vs ramp",
           [controller(:velocity_hold, :target_speed), controller(:velocity_hold, :speed_ref)],
           unit: :centimeter_per_second,
           window: 10_000
    end

    panel :yaw do
      title "Yaw"
      readout "heading", controller(:yaw_hold, :heading), unit: :degree, decimals: 1
      readout "hold", controller(:yaw_hold, :hold), unit: :degree, decimals: 1

      readout "differential", controller(:yaw_hold, :differential),
        unit: :radian_per_second,
        decimals: 2

      readout "gyro bias", controller(:yaw_hold, :bias), unit: :degree_per_second, decimals: 2
      readout "turning", controller(:yaw_hold, :turning?)

      plot "heading vs hold",
           [controller(:yaw_hold, :heading), controller(:yaw_hold, :hold)],
           unit: :degree,
           window: 20_000
    end
  end

  keys do
    bind "s", command: :stand, label: "stand"
  end

  hints do
    state :disarmed, "a to arm"
    state :idle, "hold it upright and still, then s to balance"
    state :balancing, "on Drive, t takes the wheel and the arrows drive · d disarms"
    state :fallen, "wheels braked · stand it up, hold it still, then s"
    state :error, "safety error · f force-disarms"
  end
end
