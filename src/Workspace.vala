using Gee;

public class Workspace : Gtk.Overlay
{
    public ArrayList<Vte.Terminal> list_of_terminals { get; construct; }

    construct
    {
        list_of_terminals = new ArrayList<Vte.Terminal>();
    }

    public Workspace(string? workspace_str = null)
    {
        if (workspace_str == null)
            add (new Terminal(this));
        else
        {
            try
            {
                parse_workspace (workspace_str);
            }
            catch
            {
                add (new Terminal(this));
            }
        }
    }

    private void parse_workspace (string workspace_str) throws ParseError
    {
        PseudoWorkspace pwk = PseudoWorkspace.parse (workspace_str);

        if (pwk.child.get_type().is_a(typeof(PseudoTerminal)))
        {
            var pseudo_terminal = (PseudoTerminal) pwk.child;
            add (terminal_make (pseudo_terminal));
        }
        else if (pwk.child.get_type().is_a(typeof(PseudoPaned)))
        {
            var pseudo_paned = (PseudoPaned) pwk.child;
            add (mpaned_make (pseudo_paned));
        }
    }

    private Terminal terminal_make (PseudoTerminal pseudo_terminal)
    {
        return new Terminal(this, pseudo_terminal.working_dir);
    }

    private Paned mpaned_make (PseudoPaned pseudo_paned)
    {
        Gtk.Widget child1 = null;
        if (pseudo_paned.child1.get_type().is_a(typeof(PseudoPaned)))
        {
            var pseudo_paned1 = (PseudoPaned)pseudo_paned.child1;
            child1 = mpaned_make (pseudo_paned1);
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
            child2 = mpaned_make (pseudo_paned2);
        }
        else
        {
            var pseudo_terminal = (PseudoTerminal)pseudo_paned.child2;
            child2 = terminal_make (pseudo_terminal);
        }

        var paned = new Paned.make(pseudo_paned.orientation, pseudo_paned.position_percent,
            child1, child2);

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