defmodule GoatbotWeb.DashboardLive do
  @moduledoc """
  The bb_tui dashboard, with `Goatbot.TUI`, in the browser at `/tui`: the
  same tabs, keys and driving as over SSH, for a laptop next to the phone
  controller. Each browser tab is its own session; `t` on the Drive tab
  takes the wheel, so it and an SSH session can't both drive.
  """
  use BB.TUI.Live, robot: Goatbot.Robot, extensions: [Goatbot.TUI]
end
