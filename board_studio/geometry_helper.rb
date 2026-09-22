# frozen_string_literal: true

module BoardStudio
  module GeometryHelper
    module_function

    # Розраховує вектор висоти, ортогональний до базового вектора v1
    def calculate_orthogonal_vector(base_pt, target_pt, u_axis)
      v = target_pt - base_pt
      proj_len = v.dot(u_axis)
      v - Geom::Vector3d.new(u_axis.x * proj_len, u_axis.y * proj_len, u_axis.z * proj_len)
    end

    # Розраховує нормаль площини за двома векторами напрямку або дефолтними осями
    def calculate_plane_normal(u1, u2)
      normal = u1.cross(u2)
      if !normal.valid? || normal.length == 0
        normal = u1.cross(Z_AXIS)
        normal = u1.cross(Y_AXIS) if !normal.valid? || normal.length == 0
      end
      normal.normalize
    end

    # Розраховує 4 фінальні точки панелі з урахуванням зміщень/зменшення (offset_length, offset_width)
    # та повертає [p1_final, p2_final, p3_final, p4_final, raw_pts, normal]
    def calculate_panel_points(p1, p2, curr_pt, offset_len = 0, offset_wid = 0)
      v1 = p2 - p1
      return nil if v1.length == 0

      u1 = v1.normalize
      len1 = v1.length

      v_height = calculate_orthogonal_vector(p2, curr_pt, u1)

      if v_height.length < 0.001
        p3_raw = curr_pt
        p4_raw = p1 + (curr_pt - p2)
        v2 = curr_pt - p2
        u2 = v2.length > 0 ? v2.normalize : u1.cross(Z_AXIS).normalize
        len2 = v2.length
      else
        p3_raw = p2 + v_height
        p4_raw = p1 + v_height
        u2 = v_height.normalize
        len2 = v_height.length
      end

      # Зменшення з обох боків за наявності достатніх розмірів
      off_l = (offset_len && offset_len > 0 && len1 > 2 * offset_len) ? offset_len : 0
      off_w = (offset_wid && offset_wid > 0 && len2 > 2 * offset_wid) ? offset_wid : 0

      p1_final = p1.offset(u1, off_l).offset(u2, off_w)
      p2_final = p2.offset(u1.reverse, off_l).offset(u2, off_w)
      p3_final = p3_raw.offset(u1.reverse, off_l).offset(u2.reverse, off_w)
      p4_final = p4_raw.offset(u1, off_l).offset(u2.reverse, off_w)

      raw_pts = [p1, p2, p3_raw, p4_raw]
      final_pts = [p1_final, p2_final, p3_final, p4_final]
      normal = calculate_plane_normal(u1, u2)

      [final_pts, raw_pts, normal]
    end
  end
end
