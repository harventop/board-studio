# frozen_string_literal: true

require 'sketchup.rb'
require_relative 'geometry_helper'
require_relative 'preview_drawer'
require_relative 'three_point_panel_tool'

module BoardStudio
  unless file_loaded?(__FILE__)

    cmd_new = UI::Command.new("New3PointPanel") {
      Sketchup.active_model.select_tool(
        BoardStudio::ThreePointPanelTool.new(show_dialog: true)
      )
    }

    cmd_new.tooltip = "Create new panel with dialog"
    cmd_new.status_bar_text = "Create new panel by 3 points with parameters dialog"
    cmd_new.small_icon = File.join(__dir__, "icons/new.png")
    cmd_new.large_icon = File.join(__dir__, "icons/new.png")

    cmd_next = UI::Command.new("Next3PointPanel") {
      Sketchup.active_model.select_tool(
        BoardStudio::ThreePointPanelTool.new(show_dialog: false)
      )
    }

    cmd_next.tooltip = "Create next panel using previous settings"
    cmd_next.status_bar_text = "Create next panel by 3 points using previous settings without dialog"
    cmd_next.small_icon = File.join(__dir__, "icons/next.png")
    cmd_next.large_icon = File.join(__dir__, "icons/next.png")

    toolbar = UI::Toolbar.new("Panel Creator")
    toolbar.add_item(cmd_new)
    toolbar.add_item(cmd_next)
    toolbar.show

    file_loaded(__FILE__)
  end
end
