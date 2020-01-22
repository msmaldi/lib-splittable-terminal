using Gee;

public class Workspace : Gtk.Overlay
{
    public ArrayList<Vte.Terminal> list_of_terminals { get; construct; }
    private bool configured = false;
    public int minimal_terminal_width { get; protected set; }
    public int minimal_terminal_height { get; protected set; }

    public signal void configuration_changed ();
    public signal void split_failed ();

    construct
    {
        list_of_terminals = new ArrayList<Vte.Terminal>();
        minimal_terminal_width = 300;
        minimal_terminal_height = 200;
        delete_event.connect (on_delete_event);
    }

    public Workspace()
    {
    }

    public void configure (string workspace_str, Gtk.Allocation alloc = { 0, 0, 1, 1 })
    {
        try
        {
            parse_workspace (workspace_str, alloc);
        }
        catch
        {
            add (new Terminal(this));
        }
        request_resize_all_paned ();
        configured = true;
    }


    private void parse_workspace (string workspace_str, Gtk.Allocation alloc) throws ParseError
    {
        //  Gtk.Allocation alloc;
        //  get_allocation (out alloc);
        print ("%d %d\n", alloc.width, alloc.height);

        PseudoWorkspace pwk = PseudoWorkspace.parse (workspace_str);

        if (pwk.child.get_type().is_a(typeof(PseudoTerminal)))
        {
            var pseudo_terminal = (PseudoTerminal) pwk.child;
            add (terminal_make (pseudo_terminal));
        }
        else if (pwk.child.get_type().is_a(typeof(PseudoPaned)))
        {
            var pseudo_paned = (PseudoPaned) pwk.child;
            add (mpaned_make (pseudo_paned, alloc));
        }
    }

    private Terminal terminal_make (PseudoTerminal pseudo_terminal)
    {
        return new Terminal(this, pseudo_terminal.working_dir);
    }

    private Paned mpaned_make (PseudoPaned pseudo_paned, Gtk.Allocation alloc)
    {
        Gtk.Widget child1 = null;
        Gtk.Allocation alloc_child1 = { 0 };
        Gtk.Allocation alloc_child2 = { 0 };
        if (pseudo_paned.orientation == Gtk.Orientation.HORIZONTAL)
        {
            alloc_child1.width = (int)((double)alloc.width * pseudo_paned.position_percent);
            alloc_child1.height = alloc.height;
            alloc_child2.width = (int)((double)alloc.width * (1 - pseudo_paned.position_percent));
            alloc_child2.height = alloc.height;
        }
        else
        {
            alloc_child1.width = alloc.width;
            alloc_child1.height = (int)((double)alloc.height * pseudo_paned.position_percent);
            alloc_child2.width = alloc.width;
            alloc_child2.height = (int)((double)alloc.height * (1 - pseudo_paned.position_percent));
        }

        if (pseudo_paned.child1.get_type().is_a(typeof(PseudoPaned)))
        {
            var pseudo_paned1 = (PseudoPaned)pseudo_paned.child1;
            child1 = mpaned_make (pseudo_paned1, alloc_child1);
        }
        else
        {
            var pseudo_terminal = (PseudoTerminal)pseudo_paned.child1;
            child1 = terminal_make (pseudo_terminal);
        }

        Gtk.Widget child2 = null;
        if (pseudo_paned.child2.get_type().is_a(typeof(PseudoPaned)))
        {
            var pseudo_paned2 = (PseudoPaned)pseudo_paned.child2;
            child2 = mpaned_make (pseudo_paned2, alloc_child2);
        }
        else
        {
            var pseudo_terminal = (PseudoTerminal)pseudo_paned.child2;
            child2 = terminal_make (pseudo_terminal);
        }

        Paned paned = new Paned.with_allocation(this,
                pseudo_paned.orientation, alloc,
                child1, child2, pseudo_paned.position_percent);

        return paned;
    }



    public void request_resize_all_paned()
    {
        var widget = get_child();
        if (widget.get_type().is_a(typeof(Paned)))
            resize_paned_childs((Paned)widget);
    }

    private void resize_paned_childs (Paned paned)
    {
        var child1 = paned.get_child1();
        paned.update_position();

        if (child1.get_type().is_a(typeof(Paned)))
            resize_paned_childs ((Paned)child1);

        var child2 = paned.get_child2();
        if (child2.get_type().is_a(typeof(Paned)))
            resize_paned_childs ((Paned)child2);

        paned.update_position();
    }

    public string to_compact_string ()
    {
        var child = get_child ();
        var sb = new StringBuilder();
        sb.append ("w(");
        if (child.get_type().is_a(typeof(Paned)))
            sb.append (((Paned)child).to_compact_string());
        else if (child.get_type().is_a(typeof(Terminal)))
            sb.append(((Terminal)child).to_compact_string());
        sb.append (")");

        return sb.str;
    }
}