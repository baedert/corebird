



class ArrowBin : Gtk.Bin {
	private Gtk.PositionType arrow_position;
	private double arrow_align = 0.0;
	private int arrow_size = 15;

	struct Point {
		double x;
		double y;
	}

	public ArrowBin(Gtk.PositionType arrow_position) {
		this.arrow_position = arrow_position;
		set_has_window(false);
	}


	public override void get_preferred_width(out int minimum_width,
	                                         out int natural_width) {

		Gtk.Border padding;
		get_padding_and_border(out padding, null);

		int minimum = 0;
		int natural = 0;

		Gtk.Widget child = this.get_child();
		if(child != null && child.visible) {
			int child_min;
			int child_nat;
			child.get_preferred_width(out child_min, out child_nat);
			minimum += child_min;
			natural += child_nat;
		}

		minimum += padding.left + padding.right;
		natural += padding.left + padding.right;

		if(arrow_position == Gtk.PositionType.LEFT ||
		   arrow_position == Gtk.PositionType.RIGHT) {
			minimum += arrow_size;
			natural += arrow_size;
		}

		minimum_width = minimum;
		natural_width = natural;
	}

	public override void get_preferred_height(out int minimum_height,
	                                          out int natural_height) {
		Gtk.Border padding;

		get_padding_and_border (out padding, null);

		int minimum = 0;
		int natural = 0;
		Gtk.Widget child = get_child();
		if(child != null && child.visible) {
			int child_min, child_nat;
			child.get_preferred_height(out child_min, out child_nat);
			minimum = child_min;
			natural = child_nat;
		}

		minimum += padding.top + padding.bottom;
		natural += padding.top + padding.bottom;

		if(arrow_position == Gtk.PositionType.TOP ||
		   arrow_position == Gtk.PositionType.BOTTOM) {
			minimum += arrow_size;
			natural += arrow_size;
		}

		minimum_height = minimum;
		natural_height = natural;
	}

	public override void get_preferred_height_for_width (int width,
	                                                     out int minimum_height,
	                                                     out int natural_height) {
		Gtk.Border padding;

		get_padding_and_border(out padding, null);

		int minimum = 0;
		int natural = 0;
		Gtk.Widget child = get_child();
		if(child != null && child.visible) {
			int child_width = width - padding.left - padding.top;
			int child_min, child_nat;
			child.get_preferred_height_for_width(child_width, out child_min,
			                                     out child_nat);
			minimum = max(minimum, child_min);
			natural = max(natural, child_nat);
		}

		minimum += padding.top + padding.bottom;
		natural += padding.top + padding.bottom;

		if(arrow_position == Gtk.PositionType.TOP ||
		   arrow_position == Gtk.PositionType.BOTTOM) {
			minimum += arrow_size;
			natural += arrow_size;
		}

		minimum_height = minimum;
		natural_height = natural;
	}

	public override void get_preferred_width_for_height(int height,
	                                                    out int minimum_width,
	                                                    out int natural_width) {
		Gtk.Border padding;
		get_padding_and_border(out padding, null);

		int minimum = 0;
		int natural = 0;
		int child_height = height - padding.top - padding.bottom;
		Gtk.Widget child = get_child();
		if(child != null && child.visible) {
			int child_min, child_nat;
			child.get_preferred_width_for_height(child_height, out child_min,
			                                     out child_nat);
			minimum += child_min;
			natural += child_nat;
		}

		minimum += padding.left + padding.right;
		natural += padding.left + padding.right;

		if(arrow_position == Gtk.PositionType.LEFT ||
		   arrow_position == Gtk.PositionType.RIGHT) {
			minimum += arrow_size;
			natural += arrow_size;
		}

		minimum_width = minimum;
		natural_width = natural;
	}

	public override void size_allocate(Gtk.Allocation alloc) {
		Gtk.Border padding;
		Gtk.Allocation child_alloc = {};

		this.set_allocation(alloc);

		get_padding_and_border(out padding, null);

		if(this.get_realized()) {
			get_window().move_resize(alloc.x, alloc.y, alloc.width, alloc.height);
		}

		child_alloc.x = padding.left + (arrow_position == Gtk.PositionType.LEFT ?
		                                arrow_size : 0);
		child_alloc.y = padding.left + (arrow_position == Gtk.PositionType.TOP ?
		                                arrow_size : 0);

		child_alloc.height = max(1, alloc.height - padding.top - padding.bottom);
		child_alloc.width  = max(1, alloc.width - padding.left - padding.right);

		if(arrow_position == Gtk.PositionType.LEFT ||
		   arrow_position == Gtk.PositionType.RIGHT) {
			child_alloc.width -= arrow_size;
		}else
			child_alloc.height -= arrow_size;

		Gtk.Widget child = get_child();
		if(child != null && child.visible)
			child.size_allocate(child_alloc);

	}


	public override bool draw(Cairo.Context c) {
		Gtk.Border border = get_style_context().get_border(get_state_flags());
		int selected_border_radius;
		int border_width;
		int width, height, selected_border;
		double x, y, arrow_start_point;
		get_style_context().@get(get_state_flags(),
                                 "border-radius",
                                 out selected_border_radius);

		get_padding_and_border (null, out border_width);

		width  = get_allocated_width() - 2*border_width;
		height = get_allocated_height() - 2*border_width;
		selected_border = 0;

		x = y = border_width;
		if(arrow_position == Gtk.PositionType.LEFT)
			x += arrow_size;
		if(arrow_position == Gtk.PositionType.TOP)
			y += arrow_size;

		switch(arrow_position) {
			case Gtk.PositionType.TOP:
				selected_border = border.top;
				break;
			case Gtk.PositionType.BOTTOM:
				selected_border = border.bottom;
				break;
			case Gtk.PositionType.LEFT:
				selected_border = border.left;
				break;
			case Gtk.PositionType.RIGHT:
				selected_border = border.right;
				break;
		}

		if(arrow_position == Gtk.PositionType.LEFT ||
		   arrow_position == Gtk.PositionType.RIGHT) {
			width -= arrow_size;
      		arrow_start_point = arrow_size + selected_border / 2 +
      							selected_border_radius + (height - 2 *
      							(arrow_size + selected_border / 2
      							 + selected_border_radius)) * arrow_align;


		} else {
			height -= arrow_size;
			      arrow_start_point = arrow_size + selected_border / 2 + selected_border_radius +
          (width - 2 * (arrow_size + selected_border / 2 + selected_border_radius)) * arrow_align;
		}


		get_style_context().render_background(c, x, y, width, height);
		get_style_context().render_frame_gap(c, x, y, width, height,
		                                     arrow_position,
		                                     arrow_start_point - arrow_size,
		                                     arrow_start_point + arrow_size);
		this.draw_arrow(c);
		base.draw(c);

		return false;
	}

	// TODO: WTF
	private void draw_arrow(Cairo.Context c) {
		Gtk.Border border;
		int selected_border_radius;
		int border_width;
		int width, height;
		double arrow_start_point;
		int selected_border;
		Point p0 = {0, 0};
		Point p1 = {0, 0};
		Point p2 = {0, 0};
		Point p3 = {0, 0};
		Point p4 = {0, 0};

		border = get_style_context().get_border(get_state_flags());
		get_style_context().@get(get_state_flags(),
                         "border-radius",
                         out selected_border_radius);
		get_padding_and_border(null, out border_width);

		width = get_allocated_width() - 2*border_width;
		height = get_allocated_height() - 2*border_width;
		selected_border = 0;
		switch(arrow_position) {
			case Gtk.PositionType.TOP:
				selected_border = border.top;
				break;
			case Gtk.PositionType.BOTTOM:
				selected_border = border.bottom;
				break;
			case Gtk.PositionType.LEFT:
				selected_border = border.left;
				break;
			case Gtk.PositionType.RIGHT:
				selected_border = border.right;
				break;
		}

		if(arrow_position == Gtk.PositionType.LEFT ||
		   arrow_position == Gtk.PositionType.RIGHT) {
			width -= arrow_size;
      		arrow_start_point = arrow_size + selected_border / 2 +
      							selected_border_radius + (height - 2 *
      							(arrow_size + selected_border / 2
      							 + selected_border_radius)) * arrow_align;


		} else {
			height -= arrow_size;
			      arrow_start_point = arrow_size + selected_border / 2 + selected_border_radius +
          (width - 2 * (arrow_size + selected_border / 2 + selected_border_radius)) * arrow_align;
		}


	  switch (arrow_position)
	    {
	      case Gtk.PositionType.TOP:
	        p0.x = border_width + arrow_start_point - arrow_size;
	        p0.y = border_width + border.top + arrow_size;
	        p1.x = p0.x;
	        p1.y = p0.y - border.top;
	        p2.x = p1.x + arrow_size;
	        p2.y = p1.y - arrow_size;
	        p3.x = p2.x + arrow_size;
	        p3.y = p1.y;
	        p4.x = p3.x;
	        p4.y = p0.y;
	        break;
	      case Gtk.PositionType.BOTTOM:
	        p0.x = border_width + arrow_start_point - arrow_size;
	        p0.y = border_width + height - border.bottom;
	        p1.x = p0.x;
	        p1.y = p0.y + border.bottom;
	        p2.x = p1.x + arrow_size;
	        p2.y = p1.y + arrow_size;
	        p3.x = p2.x + arrow_size;
	        p3.y = p1.y;
	        p4.x = p3.x;
	        p4.y = p0.y;
	        break;
	      case Gtk.PositionType.LEFT:
	        p0.x = border_width + arrow_size + border.left;
	        p0.y = border_width + arrow_start_point - arrow_size;
	        p1.x = p0.x - border.left;
	        p1.y = p0.y;
	        p2.x = p1.x - arrow_size;
	        p2.y = p1.y + arrow_size;
	        p3.x = p1.x;
	        p3.y = p2.y + arrow_size;
	        p4.x = p0.x;
	        p4.y = p3.y;
	        break;
	      case Gtk.PositionType.RIGHT:
	        p0.x = border_width + width - border.left;
	        p0.y = border_width + arrow_start_point - arrow_size;
	        p1.x = p0.x + border.left;
	        p1.y = p0.y;
	        p2.x = p1.x + arrow_size;
	        p2.y = p1.y + arrow_size;
	        p3.x = p1.x;
	        p3.y = p2.y + arrow_size;
	        p4.x = p0.x;
	        p4.y = p3.y;
	        break;
	    }


	    c.save();
	    c.set_line_width(border.bottom);
	    c.set_line_cap(Cairo.LineCap.ROUND);
	    c.set_line_join(Cairo.LineJoin.ROUND);

	    c.move_to(p0.x, p0.y);
	    c.line_to(p1.x, p1.y);
	    c.line_to(p2.x, p2.y);
	    c.line_to(p3.x, p3.y);
	    c.line_to(p4.x, p4.y);

	    Gdk.RGBA color;
	    color = get_style_context().get_background_color(get_state_flags());
	    c.set_source_rgba(color.red, color.green, color.blue, color.alpha);
	    c.fill();

	    c.move_to(p1.x, p1.y);
	    c.line_to(p2.x, p2.y);
	    c.line_to(p3.x, p3.y);

	    color = get_style_context().get_border_color(get_state_flags());
	    c.set_source_rgba(color.red, color.green, color.blue, color.alpha);
	    c.stroke();
	    c.restore();

	}

	private void get_padding_and_border(out Gtk.Border border, out int border_width) {
		int16 bd_width = (int16)get_border_width();

		Gtk.StateFlags state_flags = get_state_flags();
		border = this.get_style_context().get_padding(state_flags);
		Gtk.Border tmp = get_style_context().get_border(state_flags);
		border.top    += tmp.top + bd_width;
		border.right  += tmp.right + bd_width;
		border.bottom += tmp.bottom + bd_width;
		border.left   += tmp.left + bd_width;
	}



	private int max(int a, int b){
		if(a < b)
			return b;
		return a;
	}
}