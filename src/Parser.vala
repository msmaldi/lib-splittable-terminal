public errordomain ParseError
{
    TERMINAL_DECLARATION,
    PANED_DECLARATION,
    WORKSPACE_DECLARATION
}

public class PseudoTerminal : Object
{
    public string working_dir { get; private set; }

    public PseudoTerminal (string working_dir)
    {
        this.working_dir = working_dir;
    }

    enum State
    {
        CHILD_DECLARATOR,
        OPEN_PARENTS,
        PRE_WORKING_DIR,
        WORKING_DIR,
        CLOSE_PARENTS,
        SUCCESS
    }

    public static PseudoTerminal parse (string terminal_str) throws ParseError
    {
        State state = CHILD_DECLARATOR;
        var working_dir_sb = new StringBuilder();
        for (int i = 0; i < terminal_str.length; i++)
        {
            char c = terminal_str[i];
            switch (state)
            {
            case State.CHILD_DECLARATOR:
                if (c != 't')
                    throw new ParseError.TERMINAL_DECLARATION("Expected 't' but found %c.", c);
                else
                    state = State.OPEN_PARENTS;
            break;
            case State.OPEN_PARENTS:
                if (c != '(')
                    throw new ParseError.TERMINAL_DECLARATION("Expected '(' but found %c.", c);
                else
                    state = State.PRE_WORKING_DIR;
            break;
            case State.PRE_WORKING_DIR:
                if (c != '\'')
                    throw new ParseError.TERMINAL_DECLARATION("Expected '\'' but found %c.", c);
                else
                    state = State.WORKING_DIR;
            break;
            case State.WORKING_DIR:
                if (c == '\'')
                    state = State.CLOSE_PARENTS;
                else
                    working_dir_sb.append_c(c);
            break;
            case State.CLOSE_PARENTS:
                if (c != ')')
                    throw new ParseError.TERMINAL_DECLARATION("Expected ')' but found %c.", c);
                else
                    state = State.SUCCESS;
            break;
            case State.SUCCESS:
                throw new ParseError.TERMINAL_DECLARATION("Expected 'null' but found %c.", c);
            }
        }
        return new PseudoTerminal (working_dir_sb.str);
    }
}

public class PseudoPaned : Object
{
    public double position_percent { get; private set; }
    public Gtk.Orientation orientation { get; private set; }
    public Object child1 { get; private set; }
    public Object child2 { get; private set; }

    public PseudoPaned (double position_percent, Gtk.Orientation orientation,
                        Object child1, Object child2)
    {
        this.position_percent = position_percent;
        this.orientation = orientation;
        this.child1 = child1;
        this.child2 = child2;
    }

    enum State
    {
        CHILD_DECLARATOR,
        OPEN_PARENTS,
        PERCENT,
        CHILD1,
        PRE_CHILD1_INSIDE,
        CHILD1_INSIDE,
        SEPARATOR,
        CHILD2,
        PRE_CHILD2_INSIDE,
        CHILD2_INSIDE,
        CLOSE_PARENTS,
        SUCCESS
    }

    public static PseudoPaned parse (string paned_str) throws ParseError
    {
        State state = CHILD_DECLARATOR;

        Gtk.Orientation orientation = Gtk.Orientation.HORIZONTAL;
        var percent_sb = new StringBuilder();
        double percent = -1;

        char child1_type = 0;
        var child1_sb = new StringBuilder();
        int child1_level = 0;

        char child2_type = 0;
        var child2_sb = new StringBuilder();
        int child2_level = 0;

        for (int i = 0; i < paned_str.length; i++)
        {
            char c = paned_str[i];
            switch (state)
            {
            case State.CHILD_DECLARATOR:
                if (c == 'h')
                    orientation = Gtk.Orientation.HORIZONTAL;
                else if (c == 'v')
                    orientation = Gtk.Orientation.VERTICAL;
                else
                    throw new ParseError.PANED_DECLARATION ("Paned declaration most be 'h' or 'v', but found %c", c);
                state = State.OPEN_PARENTS;
            break;
            case State.OPEN_PARENTS:
                if (c != '(')
                    throw new ParseError.PANED_DECLARATION("Expected '(' but found %c.", c);
                else
                    state = State.PERCENT;
            break;
            case State.PERCENT:
                if (c.isdigit() || c == '.')
                    percent_sb.append_c (c);
                else if (c == ';')
                {
                    if (!double.try_parse (percent_sb.str, out percent))
                        throw new ParseError.PANED_DECLARATION ("Failed to parse double %s.", percent_sb.str);
                    state = State.CHILD1;
                }
                else
                    throw new ParseError.PANED_DECLARATION("Expected a number.");
            break;
            case State.CHILD1:
                if (c == 't' || c == 'h' || c == 'v')
                {
                    child1_type = c;
                    child1_sb.append_c (c);
                    state = State.PRE_CHILD1_INSIDE;
                }
                else throw new ParseError.PANED_DECLARATION("Expected 't' 'h' or 'v', but found %c.", c);
            break;
            case State.PRE_CHILD1_INSIDE:
                if (c == '(')
                {
                    child1_sb.append_c (c);
                    child1_level++;
                    state = State.CHILD1_INSIDE;
                }
                else throw new ParseError.PANED_DECLARATION("Expected '(', but found %c.", c);
            break;
            case State.CHILD1_INSIDE:
                if (c == '(')
                {
                    child1_sb.append_c (c);
                    child1_level++;
                }
                else if (c == ')')
                {
                    child1_sb.append_c (c);
                    child1_level--;
                    if (child1_level == 0)
                        state = State.SEPARATOR;
                }
                else
                {
                    child1_sb.append_c (c);
                }
            break;
            case State.SEPARATOR:
                if (c == '|')
                    state = State.CHILD2;
                else throw new ParseError.PANED_DECLARATION("Expected '(', but found %c.", c);
            break;
            case State.CHILD2:
                if (c == 't' || c == 'h' || c == 'v')
                {
                    child2_type = c;
                    child2_sb.append_c (c);
                    state = State.PRE_CHILD2_INSIDE;
                }
                else throw new ParseError.PANED_DECLARATION("Expected 't' 'h' or 'v', but found %c.", c);
            break;
            case State.PRE_CHILD2_INSIDE:
                if (c == '(')
                {
                    child2_sb.append_c (c);
                    child2_level++;
                    state = State.CHILD2_INSIDE;
                }
                else throw new ParseError.PANED_DECLARATION("Expected '(', but found %c.", c);
            break;
            case State.CHILD2_INSIDE:
                if (c == '(')
                {
                    child2_sb.append_c (c);
                    child2_level++;
                }
                else if (c == ')')
                {
                    child2_sb.append_c (c);
                    child2_level--;
                    if (child2_level == 0)
                        state = State.CLOSE_PARENTS;
                }
                else
                {
                    child2_sb.append_c (c);
                }
            break;
            case State.CLOSE_PARENTS:
                if (c == ')')
                    state = State.SUCCESS;
                else
                    throw new ParseError.PANED_DECLARATION("Expected ')', but found %c.", c);
            break;
            case State.SUCCESS:
                throw new ParseError.PANED_DECLARATION("Expected 'null' but found %c.", c);
            }
        }
        if (!(0.0 < percent < 1.0))
            throw new ParseError.PANED_DECLARATION("Percent must be > 0 and < 1.");

        Object child1;
        if (child1_type == 't')
            child1 = PseudoTerminal.parse (child1_sb.str);
        else
            child1 = PseudoPaned.parse (child1_sb.str);

        Object child2;
        if (child2_type == 't')
            child2 = PseudoTerminal.parse (child2_sb.str);
        else
            child2 = PseudoPaned.parse (child2_sb.str);

        return new PseudoPaned(percent, orientation, child1, child2);
    }
}

public class PseudoWorkspace : Object
{
    public Object child { get; private set; }

    public PseudoWorkspace (Object child)
    {
        this.child = child;
    }

    enum State
    {
        CHILD_DECLARATOR,
        OPEN_PARENTS,
        PERCENT,
        CHILD,
        PRE_CHILD_INSIDE,
        CHILD_INSIDE,
        CLOSE_PARENTS,
        SUCCESS
    }

    public static PseudoWorkspace parse (string workspace_str) throws ParseError
    {
        State state = CHILD_DECLARATOR;

        char child_type = 0;
        var child_sb = new StringBuilder();
        int child_level = 0;

        for (int i = 0; i < workspace_str.length; i++)
        {
            char c = workspace_str[i];
            switch (state)
            {
            case State.CHILD_DECLARATOR:
                if (c != 'w')
                    throw new ParseError.WORKSPACE_DECLARATION ("Paned declaration must be 'w', but found %c", c);
                else
                    state = State.OPEN_PARENTS;
            break;
            case State.OPEN_PARENTS:
                if (c == '(')
                {
                    state = State.CHILD;
                }
                else
                    throw new ParseError.WORKSPACE_DECLARATION ("Paned declaration must be 'w', but found %c", c);
            break;
            case State.CHILD:
                if (c == 't' || c == 'h' || c == 'v')
                {
                    child_type = c;
                    child_sb.append_c (c);
                    state = State.PRE_CHILD_INSIDE;
                }
                else throw new ParseError.WORKSPACE_DECLARATION("Expected 't' 'h' or 'v', but found %c.", c);
            break;
            case State.PRE_CHILD_INSIDE:
                if (c == '(')
                {
                    child_sb.append_c (c);
                    child_level++;
                    state = State.CHILD_INSIDE;
                }
                else throw new ParseError.WORKSPACE_DECLARATION("Expected '(', but found %c.", c);
            break;
            case State.CHILD_INSIDE:
                if (c == '(')
                {
                    child_sb.append_c (c);
                    child_level++;
                }
                else if (c == ')')
                {
                    child_sb.append_c (c);
                    child_level--;
                    if (child_level == 0)
                        state = State.CLOSE_PARENTS;
                }
                else
                {
                    child_sb.append_c (c);
                }
            break;
            case State.CLOSE_PARENTS:
                if (c == ')')
                    state = State.SUCCESS;
                else
                    throw new ParseError.WORKSPACE_DECLARATION("Expected ')', but found %c.", c);
            break;
            case State.SUCCESS:
                throw new ParseError.WORKSPACE_DECLARATION("Expected 'null' but found %c.", c);
            }
        }

        Object child;
        if (child_type == 't')
            child = PseudoTerminal.parse (child_sb.str);
        else
            child = PseudoPaned.parse (child_sb.str);

        return new PseudoWorkspace (child);
    }
}