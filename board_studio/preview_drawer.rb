# frozen_string_literal: true

module BoardStudio
  module PreviewDrawer
    COLOR_BASE_LINE   = "black"
    COLOR_OUTLINE     = "blue"
    COLOR_FACE        = Sketchup::Color.new(0, 120, 255, 60)
    COLOR_TOP_FACE    = Sketchup::Color.new(0, 150, 255, 45)
    COLOR_SIDE_FACE   = Sketchup::Color.new(0, 120, 255, 30)
    COLOR_3D_EDGES    = Sketchup::Color.new(0, 80, 180, 160)
    COLOR_RAW_OUTLINE = Sketchup::Color.new(120, 120, 120, 180)

    module_function

    # Малює лінію побудови (від першої точки до курсору або базову лінію)
    def draw_segment(view, pt1, pt2, color = COLOR_BASE_LINE, width = 2)
      return unless pt1 && pt2 && pt1 != pt2
      view.line_width = width
      view.drawing_color = color
      view.draw(GL_LINES, [pt1, pt2])
    end

    # Малює пунктирний контур початкового габариту (якщо задано зміщення)
    def draw_raw_boundary(view, raw_pts)
      return unless raw_pts && raw_pts.length == 4
      view.line_width = 1
      view.line_stipple = "-.-"
      view.drawing_color = COLOR_RAW_OUTLINE
      view.draw(GL_LINE_LOOP, raw_pts)
      view.line_stipple = ""
    end

    # Малює 2D контур та напівпрозору підсвітку площини
    def draw_plane(view, pts)
      return unless pts && pts.length == 4

      # Контур
      view.drawing_color = COLOR_OUTLINE
      view.line_width = 2
      view.draw(GL_LINE_LOOP, pts)

      # Заповнення
      view.drawing_color = COLOR_FACE
      view.draw(GL_POLYGON, pts)
    end

    # Малює 3D об'ємне прев'ю товщини
    def draw_3d_preview(view, pts, normal, thickness, flip_push)
      return unless pts && pts.length == 4 && normal && normal.valid? && thickness && thickness.abs > 0

      p1, p2, p3, p4 = pts
      push_v = normal.clone
      push_v.reverse! if flip_push
      push_v.length = thickness

      q1 = p1.offset(push_v)
      q2 = p2.offset(push_v)
      q3 = p3.offset(push_v)
      q4 = p4.offset(push_v)

      # Верхня грань
      view.drawing_color = COLOR_TOP_FACE
      view.draw(GL_POLYGON, [q1, q2, q3, q4])

      # Бокові грані
      view.drawing_color = COLOR_SIDE_FACE
      view.draw(GL_POLYGON, [p1, p2, q2, q1])
      view.draw(GL_POLYGON, [p2, p3, q3, q2])
      view.draw(GL_POLYGON, [p3, p4, q4, q3])
      view.draw(GL_POLYGON, [p4, p1, q1, q4])

      # Каркасні лінії 3D об'єму
      view.line_width = 1
      view.drawing_color = COLOR_3D_EDGES
      view.draw(GL_LINE_LOOP, [q1, q2, q3, q4])
      view.draw(GL_LINES, [p1, q1, p2, q2, p3, q3, p4, q4])
    end
  end
end
