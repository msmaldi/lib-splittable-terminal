using Gee;

public class Terminal : Gtk.Overlay
{
    Workspace workspace;
    Vte.Terminal terminal;
    GLib.Pid child_pid;

    public string shell;

    public Terminal (Workspace workspace, string? working_dir = null)
    {
        this.workspace = workspace;

        terminal = new Vte.Terminal();
        shell = Vte.get_user_shell ();
        Gdk.RGBA foreground_color = Gdk.RGBA ();
        foreground_color.parse("#FFFFFF");
        terminal.set_color_foreground(foreground_color);
        var font = Pango.FontDescription.from_string ("Terminus 16");
        terminal.font_scale = 1.25;
        terminal.set_font (font);
        //terminal.cursor_shape = Vte.CursorShape.UNDERLINE;
        if (working_dir == null)
            working_dir = GLib.Environment.get_home_dir ();
        else if (working_dir == "~")
            working_dir = GLib.Environment.get_home_dir ();
        try
        {
            terminal.spawn_sync(Vte.PtyFlags.DEFAULT, working_dir, { shell } , null, SpawnFlags.SEARCH_PATH, null, out child_pid, null);
        }
        catch(Error e)
        {
        }
        terminal.key_press_event.connect(on_key_press);

        workspace.list_of_terminals.add(terminal);
        var sw = new Gtk.ScrolledWindow (null, terminal.get_vadjustment ());
        sw.add (terminal);
        add(sw);
    }

    public bool on_key_press (Gtk.Widget widget, Gdk.EventKey key_event)
    {
        string keyname = Keymap.get_keyname (key_event);

        if (keyname == "Ctrl + Shift + h")
            return split (Gtk.Orientation.HORIZONTAL, false);
        else if (keyname == "Ctrl + Shift + j")
            return split (Gtk.Orientation.VERTICAL, true);
        else if (keyname == "Ctrl + Shift + k")
            return split (Gtk.Orientation.VERTICAL, false);
        else if (keyname == "Ctrl + Shift + l")
            return split (Gtk.Orientation.HORIZONTAL, true);
        else if (keyname == "Alt + h")
            return move_child_left();
        else if (keyname == "Alt + j")
            return move_child_down();
        else if (keyname == "Alt + k")
            return move_child_up();
        else if (keyname == "Alt + l")
            return move_child_right();
        else if (keyname == "Ctrl + Shift + ?")
            return debug_list_terminal();
        else if (keyname == "Ctrl + Shift + c")
            return copy_clipboard();
        else if (keyname == "Ctrl + Shift + v")
            return paste_clipboard();
        else if (keyname == "Ctrl + Shift + q")
            return close_child_terminal ();
        else
            return false;
    }

    private bool copy_clipboard ()
    {
        terminal.copy_clipboard ();
        return true;
    }

    private bool paste_clipboard ()
    {
        terminal.paste_clipboard ();
        return true;
    }

    public bool debug_list_terminal()
    {
        print ("%s\n", workspace.to_compact_string ());

        return true;
    }

    public string get_shell_location ()
    {
        try
        {
            var home = GLib.Environment.get_home_dir ();
            var full_path = GLib.FileUtils.read_link ("/proc/%d/cwd".printf (child_pid));
            if (full_path.has_prefix(home))
                return "~" + full_path.substring (home.length);
            return full_path;
        }
        catch (GLib.FileError error)
        {
            return "~";
        }
    }

    public string to_compact_string()
    {
        return "t('%s')".printf(get_shell_location());
    }

    private Gtk.Allocation get_origin_allocation(Gtk.Widget w)
    {
        Gtk.Allocation alloc;
        w.get_allocation(out alloc);
        w.translate_coordinates(w.get_toplevel(), 0, 0, out alloc.x, out alloc.y);
        return alloc;
    }

    private void select_horizontal_terminal(bool left = true)
    {
        var focus_term = this;

        Gtk.Allocation rect = get_origin_allocation(focus_term);
        int y = rect.y;
        int h = rect.height;

        ArrayList<Vte.Terminal> intersects_terminals = find_intersects_horizontal_terminals(rect, left);
        if (intersects_terminals.size > 0) {
            ArrayList<Vte.Terminal> same_coordinate_terminals = new ArrayList<Vte.Terminal>();
            foreach (Vte.Terminal t in intersects_terminals) {
                Gtk.Allocation alloc = get_origin_allocation(t);

                if (alloc.y == y) {
                    same_coordinate_terminals.add(t);
                }
            }

            if (same_coordinate_terminals.size > 0) {
                same_coordinate_terminals[0].grab_focus();
            } else {
                ArrayList<Vte.Terminal> bigger_match_terminals = new ArrayList<Vte.Terminal>();
                foreach (Vte.Terminal t in intersects_terminals) {
                    Gtk.Allocation alloc = get_origin_allocation(t);;

                    if (alloc.y < y && alloc.y + alloc.height >= y + h) {
                        bigger_match_terminals.add(t);
                    }
                }

                if (bigger_match_terminals.size > 0) {
                    bigger_match_terminals[0].grab_focus();
                } else {
                    Vte.Terminal biggest_intersectant_terminal = null;
                    int area = 0;
                    foreach (Vte.Terminal t in intersects_terminals) {
                        Gtk.Allocation alloc = get_origin_allocation(t);;

                        int term_area = alloc.height + h - (alloc.y - y).abs() - (alloc.y + alloc.height - y - h).abs() / 2;
                        if (term_area > area) {
                            biggest_intersectant_terminal = t;
                        }
                    }

                    if (biggest_intersectant_terminal != null) {
                        biggest_intersectant_terminal.grab_focus();
                    }
                }
            }
        }
    }

    private void select_vertical_terminal(bool up = true)
    {
        var focus_term = this;

        Gtk.Allocation rect = get_origin_allocation(focus_term);
        int x = rect.x;
        int w = rect.width;

        ArrayList<Vte.Terminal> intersects_terminals = find_intersects_vertical_terminals(rect, up);
        if (intersects_terminals.size > 0) {
            var same_coordinate_terminals = new ArrayList<Vte.Terminal>();
            foreach (Vte.Terminal t in intersects_terminals) {
                Gtk.Allocation alloc = get_origin_allocation(t);

                if (alloc.x == x) {
                    same_coordinate_terminals.add(t);
                }
            }

            if (same_coordinate_terminals.size > 0) {
                same_coordinate_terminals[0].grab_focus();
            } else {
                var bigger_match_terminals = new ArrayList<Vte.Terminal>();
                foreach (Vte.Terminal t in intersects_terminals) {
                    Gtk.Allocation alloc = get_origin_allocation(t);;

                    if (alloc.x < x && alloc.x + alloc.width >= x + w) {
                        bigger_match_terminals.add(t);
                    }
                }

                if (bigger_match_terminals.size > 0) {
                    bigger_match_terminals[0].grab_focus();
                } else {
                    Vte.Terminal biggest_intersectant_terminal = null;
                    int area = 0;
                    foreach (Vte.Terminal t in intersects_terminals) {
                        Gtk.Allocation alloc = get_origin_allocation(t);;

                        int term_area = alloc.width + w - (alloc.x - x).abs() - (alloc.x + alloc.width - x - w).abs() / 2;
                        if (term_area > area) {
                            biggest_intersectant_terminal = t;
                        }
                    }

                    if (biggest_intersectant_terminal != null) {
                        biggest_intersectant_terminal.grab_focus();
                    }
                }
            }
        }
    }

    int PANED_HANDLE_SIZE = 1;

    public ArrayList<Vte.Terminal> find_intersects_horizontal_terminals (Gtk.Allocation rect, bool left = true)
    {
        ArrayList<Vte.Terminal> intersects_terminals = new ArrayList<Vte.Terminal>();
        foreach (Vte.Terminal t in workspace.list_of_terminals) {
            Gtk.Allocation alloc = get_origin_allocation(t);
            if (alloc.y < rect.y + rect.height + PANED_HANDLE_SIZE && alloc.y + alloc.height + PANED_HANDLE_SIZE > rect.y)
            {
                if (left)
                {
                    if (alloc.x + alloc.width + PANED_HANDLE_SIZE == rect.x)
                        intersects_terminals.add(t);
                }
                else if (alloc.x == rect.x + rect.width + PANED_HANDLE_SIZE)
                    intersects_terminals.add(t);
            }
        }

        return intersects_terminals;
    }

    public ArrayList<Vte.Terminal> find_intersects_vertical_terminals (Gtk.Allocation rect, bool up = true)
    {
        ArrayList<Vte.Terminal> intersects_terminals = new ArrayList<Vte.Terminal>();
        foreach (Vte.Terminal t in workspace.list_of_terminals)
        {
            Gtk.Allocation alloc = get_origin_allocation(t);
            if (alloc.x < rect.x + rect.width + PANED_HANDLE_SIZE && alloc.x + alloc.width + PANED_HANDLE_SIZE > rect.x)
            {
                if (up)
                {
                    if (alloc.y + alloc.height + PANED_HANDLE_SIZE == rect.y)
                        intersects_terminals.add(t);
                }
                else if (alloc.y == rect.y + rect.height + PANED_HANDLE_SIZE)
                    intersects_terminals.add(t);
            }
        }

        return intersects_terminals;
    }

    public bool move_child_left ()
    {
        select_horizontal_terminal (true);
        return true;
    }

    public bool move_child_down ()
    {
        select_vertical_terminal (false);
        return true;
    }

    public bool move_child_up ()
    {
        select_vertical_terminal (true);
        return true;
    }

    public bool move_child_right ()
    {
        select_horizontal_terminal (false);
        return true;
    }

    public bool close_child_terminal ()
    {
        Gtk.Widget parent_widget = (Gtk.Widget) get_parent();
        if (!parent_widget.get_type().is_a(typeof(Paned)))
            return true;

        Paned parent_paned = (Paned)parent_widget;

        Gtk.Widget paned_child1 = parent_paned.get_child1();
        Gtk.Widget paned_child2 = parent_paned.get_child2();

        Gtk.Widget child_not_deleted =
            this == paned_child1 ? paned_child2 : paned_child1;
        int child_n = this == paned_child1 ? 1 : 2;

        workspace.list_of_terminals.remove (this.terminal);
        Gtk.Widget parent_of_paned = (Gtk.Widget) parent_widget.get_parent();

        ((Gtk.Container) parent_paned).remove (paned_child2);
        ((Gtk.Container) parent_paned).remove (paned_child1);
        ((Gtk.Container) parent_of_paned).remove (parent_paned);
        ((Gtk.Container) parent_of_paned).add (child_not_deleted);
        workspace.show_all ();

        if (child_not_deleted.get_type().is_a(typeof(Terminal)))
        {
            var terminal_widget = ((Terminal) child_not_deleted);
            terminal_widget.terminal.grab_focus();
        }
        if (child_not_deleted.get_type().is_a(typeof(Paned)))
        {
            var paned_widget = ((Paned) child_not_deleted);
            if (child_n == 1)
            {
                while (!paned_widget.get_child1().get_type().is_a(typeof(Terminal)))
                    paned_widget = (Paned)paned_widget.get_child1();

                var terminal_widget = ((Terminal) (paned_widget.get_child1()));
                terminal_widget.terminal.grab_focus();
            }
            else
            {
                while (!paned_widget.get_child2().get_type().is_a(typeof(Terminal)))
                    paned_widget = (Paned)paned_widget.get_child2();

                var terminal_widget = ((Terminal) (paned_widget.get_child2()));
                terminal_widget.terminal.grab_focus();
            }
        }

        return true;
    }

    public bool split (Gtk.Orientation orientation, bool focus_on_child)
    {
        Gtk.Allocation alloc;
        get_allocation(out alloc);

        Gtk.Widget parent_widget = get_parent();
        ((Gtk.Container) parent_widget).remove(this);
        var new_terminal = new Terminal(workspace);

        var paned = new Paned.with_allocation (orientation, alloc, this, new_terminal);
        ((Gtk.Container) parent_widget).add(paned);
        workspace.show_all ();

        if (focus_on_child)
            new_terminal.terminal.grab_focus ();
        else
            terminal.grab_focus();

        return true;
    }
}

public class Keymap
{
    public static string get_keyname (Gdk.EventKey key_event)
    {
        if ((key_event.is_modifier) != 0)
            return "";

        var key_modifiers = get_key_event_modifiers(key_event);
        var key_name = get_key_name(key_event.keyval);

        if (key_modifiers.length == 0)
            return key_name;

        var name = "";
        foreach (string modifier in key_modifiers)
            name += modifier + " + ";
        name += key_name;

        return name;
    }

    public static string[] get_key_event_modifiers(Gdk.EventKey key_event)
    {
        string[] modifiers = {};

        if ((key_event.state & Gdk.ModifierType.CONTROL_MASK) != 0)
            modifiers += "Ctrl";

        if ((key_event.state & Gdk.ModifierType.SUPER_MASK) != 0)
            modifiers += "Super";

        if ((key_event.state & Gdk.ModifierType.HYPER_MASK) != 0)
            modifiers += "Hyper";

        if ((key_event.state & Gdk.ModifierType.MOD1_MASK) != 0)
            modifiers += "Alt";

        if ((key_event.state & Gdk.ModifierType.SHIFT_MASK) != 0)
            modifiers += "Shift";

        return modifiers;
    }

    public static string get_key_name(uint keyval)
    {
        unichar key_unicode = Gdk.keyval_to_unicode(Gdk.keyval_to_lower(keyval));

        if (key_unicode == 0)
        {
            var keyname = Gdk.keyval_name(keyval);
            if (keyname == null)
                return "";
            else if (keyname == "ISO_Left_Tab")
                return "Tab";
            else
                return keyname;
        }
        else
        {
            if (key_unicode == 13)
                return "Enter";
            else if (key_unicode == 9)
                return "Tab";
            else if (key_unicode == 27)
                return "Esc";
            else if (key_unicode == 8)
                return "Backspace";
            else if (key_unicode == 127)
                return "Delete";
            else if (key_unicode == 32)
                return "Space";
            else
                return key_unicode.to_string();
        }
    }
}
