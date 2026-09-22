# frozen_string_literal: true

require_relative 'geometry_helper'
require_relative 'preview_drawer'

module BoardStudio
  class ThreePointPanelTool
    # Зберігаємо останні використані налаштування на рівні класу
    @@last_thickness = 16.0
    @@last_offset_length = 0.0
    @@last_offset_width = 0.0

    def initialize(show_dialog: true)
      @t = @@last_thickness.to_f.mm
      @offset_length = @@last_offset_length.to_f.mm
      @offset_width = @@last_offset_width.to_f.mm
      @flip_push = false

      if show_dialog
        return unless show_parameters_dialog
      end

      @ip = Sketchup::InputPoint.new
      @ip_anchor = Sketchup::InputPoint.new
      @points = []
    end

    def show_parameters_dialog
      prompts  = ["Thickness (mm)", "Offset along Length (mm)", "Offset along Width/Height (mm)"]
      defaults = [@@last_thickness, @@last_offset_length, @@last_offset_width]
      input = UI.inputbox(prompts, defaults, "Create Panel Parameters")
      return false unless input

      @@last_thickness     = input[0].to_f
      @@last_offset_length = input[1].to_f
      @@last_offset_width  = input[2].to_f

      @t = @@last_thickness.mm
      @offset_length = @@last_offset_length.mm
      @offset_width  = @@last_offset_width.mm
      true
    end

    def reset(view = nil)
      @points = []
      @ip.clear
      @ip_anchor.clear
      update_status_prompt
      view.invalidate if view
    end

    def activate
      reset
    end

    def resume(view)
      view.invalidate
    end

    def deactivate(view)
      view.invalidate
    end

    def enableVCB?
      true
    end

    def onSetCursor
      UI.set_cursor(632) # Pencil cursor ID
    end

    def onKeyDown(key, repeat, flags, view)
      # VK_CONTROL = 17 (Windows) / COPY_MODIFIER_KEY
      if key == COPY_MODIFIER_KEY || key == 17 || (flags & COPY_MODIFIER_MASK != 0)
        @flip_push = !@flip_push
        update_status_prompt
        view.invalidate
      end
    end

    def onMouseMove(flags, x, y, view)
      if @points.empty?
        @ip.pick(view, x, y)
      else
        @ip.pick(view, x, y, @ip_anchor)
      end
      view.tooltip = @ip.tooltip if @ip.valid?

      update_vcb_measurements
      view.invalidate
    end

    def onUserText(text, view)
      return if @points.empty?

      begin
        val = text.to_l
      rescue ArgumentError => e
        UI.messagebox("Invalid length: #{text}")
        return
      end

      return if val == 0

      case @points.length
      when 1
        handle_vcb_first_segment(val)
      when 2
        handle_vcb_second_segment(val)
        create_panel
        reset(view)
      end

      view.invalidate
    end

    def draw(view)
      @ip.draw(view) if @ip.valid?
      return if @points.empty?

      curr_pt = @ip.valid? ? @ip.position : nil

      case @points.length
      when 1
        PreviewDrawer.draw_segment(view, @points[0], curr_pt)

      when 2
        p1 = @points[0]
        p2 = @points[1]
        PreviewDrawer.draw_segment(view, p1, p2)

        if curr_pt && curr_pt != p2
          final_pts, raw_pts, normal = GeometryHelper.calculate_panel_points(
            p1, p2, curr_pt, @offset_length, @offset_width
          )
          return unless final_pts

          if (@offset_length && @offset_length != 0) || (@offset_width && @offset_width != 0)
            PreviewDrawer.draw_raw_boundary(view, raw_pts)
          end

          PreviewDrawer.draw_plane(view, final_pts)
          PreviewDrawer.draw_3d_preview(view, final_pts, normal, @t, @flip_push)
        end
      end
    end

    def onLButtonDown(flags, x, y, view)
      if @points.empty?
        @ip.pick(view, x, y)
      else
        @ip.pick(view, x, y, @ip_anchor)
      end
      return unless @ip.valid?

      pt = @ip.position
      return if @points.any? && @points.last == pt

      @points << pt
      @ip_anchor.copy!(@ip)

      case @points.length
      when 1
        update_status_prompt
        Sketchup.set_status_text("Length", SB_VCB_LABEL)
      when 2
        update_status_prompt
        Sketchup.set_status_text("Height", SB_VCB_LABEL)
      when 3
        create_panel
        reset(view)
      end

      view.invalidate
    end

    def onCancel(reason, view)
      reset(view)
    end

    def create_panel
      model = Sketchup.active_model
      ents  = model.active_entities

      p1, p2, curr_pt = @points
      final_pts, _, normal = GeometryHelper.calculate_panel_points(
        p1, p2, curr_pt, @offset_length, @offset_width
      )
      return unless final_pts

      p1_f, p2_f, p3_f, p4_f = final_pts
      return if normal.length == 0

      model.start_operation("3-Point Panel", true)

      group = ents.add_group
      e = group.entities

      face = e.add_face(p1_f, p2_f, p3_f, p4_f)
      if face
        target_normal = normal.clone
        target_normal.reverse! if @flip_push

        face.reverse! if face.normal.dot(target_normal) < 0
        face.pushpull(@t)
      end

      model.commit_operation
    end

    private

    def update_status_prompt
      ctrl_hint = " (Ctrl = Flip push direction)"
      case @points.length
      when 0
        Sketchup.set_status_text("Click first corner" + ctrl_hint, SB_PROMPT)
      when 1
        Sketchup.set_status_text("Click second point (width)" + ctrl_hint, SB_PROMPT)
      when 2
        dir_text = @flip_push ? "[-]" : "[+]"
        Sketchup.set_status_text("Click third point (height) #{dir_text}" + ctrl_hint, SB_PROMPT)
      end
    end

    def update_vcb_measurements
      case @points.length
      when 1
        if @ip.valid? && @ip.position != @points[0]
          length = @points[0].distance(@ip.position)
          Sketchup.set_status_text("Length", SB_VCB_LABEL)
          Sketchup.set_status_text(length.to_s, SB_VCB_VALUE)
        end
      when 2
        p1 = @points[0]
        p2 = @points[1]
        if @ip.valid? && @ip.position != p2
          v1 = p2 - p1
          if v1.length > 0
            u1 = v1.normalize
            v_height = GeometryHelper.calculate_orthogonal_vector(p2, @ip.position, u1)
            Sketchup.set_status_text("Height", SB_VCB_LABEL)
            Sketchup.set_status_text(v_height.length.to_s, SB_VCB_VALUE)
          end
        end
      end
    end

    def handle_vcb_first_segment(val)
      p1 = @points[0]
      curr_pt = @ip.valid? ? @ip.position : nil
      vec = curr_pt && curr_pt != p1 ? (curr_pt - p1) : X_AXIS
      vec = X_AXIS if vec.length == 0
      vec = vec.normalize
      vec.length = val

      @points << p1.offset(vec)
      @ip_anchor.clear
      update_status_prompt
      Sketchup.set_status_text("Height", SB_VCB_LABEL)
      Sketchup.set_status_text("", SB_VCB_VALUE)
    end

    def handle_vcb_second_segment(val)
      p1 = @points[0]
      p2 = @points[1]
      v1 = p2 - p1
      return if v1.length == 0

      u1 = v1.normalize
      curr_pt = @ip.valid? ? @ip.position : nil

      v_height = nil
      if curr_pt && curr_pt != p2
        v_h = GeometryHelper.calculate_orthogonal_vector(p2, curr_pt, u1)
        v_height = v_h.normalize if v_h.length > 0
      end

      if v_height.nil?
        normal = GeometryHelper.calculate_plane_normal(u1, Z_AXIS)
        v_height = normal.cross(u1).normalize
      end

      v_height.length = val
      @points << p2.offset(v_height)
    end
  end
end
