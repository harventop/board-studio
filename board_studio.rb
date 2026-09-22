# frozen_string_literal: true

require 'sketchup.rb'
require 'extensions.rb'

module BoardStudio
  EXTENSION_NAME = "Board Studio"

  unless file_loaded?(__FILE__)
    extension = SketchupExtension.new(
      EXTENSION_NAME,
      "board_studio/main.rb"
    )

    extension.version     = "1.0.0"
    extension.creator     = "harven"
    extension.description = "Plugin for creating parametric panels"

    Sketchup.register_extension(extension, true)
    file_loaded(__FILE__)

    UI.menu("Extensions").add_item("New 3-Point Panel") {
      Sketchup.active_model.select_tool(BoardStudio::ThreePointPanelTool.new(show_dialog: true))
    }
    UI.menu("Extensions").add_item("Next 3-Point Panel") {
      Sketchup.active_model.select_tool(BoardStudio::ThreePointPanelTool.new(show_dialog: false))
    }
  end
end