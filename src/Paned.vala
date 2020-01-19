public class Paned : Gtk.Paned
{
    // Sets the position of the divider between the two panes.
    // Percent is a double where 1.0 is 100%
    private double position_percent;
    private bool is_button_press = false;

    private Paned (Gtk.Orientation orientation,
                   Gtk.Widget child1, Gtk.Widget child2)
    {
        Object (orientation: orientation);
        draw.connect(on_draw);
        button_release_event.connect(button_release);
        button_press_event.connect(button_press);
        pack1 (child1, true, false);
        pack2 (child2, true, false);
    }

    public Paned.with_allocation (Gtk.Orientation orientation,
                                  Gtk.Allocation alloc,
                                  Gtk.Widget child1, Gtk.Widget child2,
                                  double position_percent = 0.5)
    {
        this (orientation, child1, child2);
        this.position_percent = position_percent;

        if (orientation == Gtk.Orientation.HORIZONTAL)
        {
            int width = (int)((double)alloc.width * position_percent);
            set_position(width);
        }
        else
        {
            int height = (int)((double)alloc.height * position_percent);
            set_position(height);
        }
    }

    public Paned.make (Gtk.Orientation orientation,
                       double position_percent,
                       Gtk.Widget child1, Gtk.Widget child2)
    {
        this (orientation, child1, child2);
        this.position_percent = position_percent;
    }

    private new void propagate_draw (Gtk.Container widget, Cairo.Context cr)
    {
        if (widget.get_children().length() > 0)
            foreach (Gtk.Widget child in widget.get_children())
                widget.propagate_draw(child, cr);
    }

    private bool on_draw (Gtk.Widget widget, Cairo.Context cr)
    {
        var paned_widget = (Paned) widget;
        propagate_draw(paned_widget, cr);

        if (!is_button_press)
            update_position ();

        return true;
    }

    public bool button_press (Gdk.EventButton event)
    {
        is_button_press = true;
        return false;
    }

    public bool button_release (Gdk.EventButton event)
    {
        is_button_press = false;
        Gtk.Allocation alloc;
        get_allocation(out alloc);

        if (orientation == Gtk.Orientation.HORIZONTAL)
            position_percent =  (double)get_position() / (double)alloc.width;
        else
            position_percent = (double)get_position() / (double)alloc.height;

        return true;
    }

    public void update_position ()
    {
        Gtk.Allocation alloc;
        get_allocation(out alloc);

        int correct_position = orientation == Gtk.Orientation.HORIZONTAL ?
            (int)(alloc.width * position_percent) : (int)(alloc.height * position_percent);
        while (correct_position != get_position())
            set_position(correct_position);
    }

    public string to_compact_string ()
    {
        var child1 = get_child1 ();
        var child2 = get_child2 ();

        var sb = new StringBuilder();

        if (orientation == Gtk.Orientation.HORIZONTAL)
            sb.append("h(");
        else
            sb.append("v(");

        sb.append_printf("%s;", position_percent.to_string());

        if (child1.get_type().is_a(typeof(Paned)))
            sb.append(((Paned)child1).to_compact_string());
        else if (child1.get_type().is_a(typeof(Terminal)))
            sb.append(((Terminal)child1).to_compact_string());

        sb.append("|");

        if (child2.get_type().is_a(typeof(Paned)))
            sb.append(((Paned)child2).to_compact_string());
        else if (child2.get_type().is_a(typeof(Terminal)))
            sb.append(((Terminal)child2).to_compact_string());

        sb.append (")");
        return sb.str;
    }
}