using Gee;

public class ComplexTerminal : Granite.Application
{

    public ComplexTerminal ()
    {
        Object (
            application_id: "com.github.terminal",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    Gtk.Stack stack;
    int indice = 1;
    Workspace workspace1;
    Gtk.ApplicationWindow window;

    protected override void activate ()
    {
        window = new Gtk.ApplicationWindow (this);

        window.set_default_size (1000, 700);

        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_application_prefer_dark_theme = true;

        var headerbar = new Gtk.HeaderBar ();
        headerbar.get_style_context ().add_class ("default-decoration");
        headerbar.show_close_button = true;

        var add_button = new Gtk.Button.with_label ("Add");
        add_button.get_style_context ().add_class ("suggested-action");
        add_button.clicked.connect (btn_clicked);

        add_button.valign = Gtk.Align.CENTER;
        add_button.margin_start = 10;
        add_button.margin_top = 10;
        add_button.margin_bottom = 10;
        add_button.margin_end = 10;
        headerbar.pack_start (add_button);

        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.homogeneous = true;
        stack = new Gtk.Stack ();
        stack_switcher.stack = stack;

        workspace1 = new Workspace ("w(h(0.5;v(0.666666;v(0.5;t('~/Documents')|t('~/Music'))|t('~/Public'))|v(0.666666;v(0.5;t('~/Downloads')|t('~/Pictures'))|t('~/Videos'))))");
        stack.set_transition_type (Gtk.StackTransitionType.CROSSFADE);
        stack.add_titled (workspace1, "workspace%d".printf (indice), "Alt + %d".printf (indice));
        indice++;
        stack_switcher.margin_start = 10;
        stack_switcher.margin_top = 10;
        stack_switcher.margin_bottom = 10;
        stack_switcher.margin_end = 10;
        headerbar.pack_start (stack_switcher);

        var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
        mode_switch.active = true;
        mode_switch.primary_icon_tooltip_text = ("Light background");
        mode_switch.secondary_icon_tooltip_text = ("Dark background");
        mode_switch.valign = Gtk.Align.CENTER;
        mode_switch.bind_property ("active", gtk_settings, "gtk_application_prefer_dark_theme");
        mode_switch.margin_end = 6;
        headerbar.pack_end (mode_switch);

        window.set_titlebar (headerbar);

        window.add (stack);

        window.show_all ();

        Gtk.Allocation alloc;
        window.get_allocation (out alloc);

        workspace1.show_all ();
        workspace1.request_resize_all_paned ();
        workspace1.configuration_changed.connect (workspace_changed);

        workspace1.list_of_terminals[0].grab_focus ();
    }

    private void workspace_changed ()
    {
        print ("%s\n", workspace1.to_compact_string ());
    }

    private void btn_clicked ()
    {
        if (indice > 10)
            return;
        var workspace = new Workspace ("w(h(0.5;t('~')|t('~')))");
        stack.add_titled (workspace, "workspace%d".printf (indice % 10), "Alt + %d".printf (indice % 10));
        indice++;

        Gtk.Allocation alloc;
        window.get_allocation (out alloc);

        stack.show_all ();
        workspace1.request_resize_all_paned ();
        workspace.show_all ();
    }

    private static int main (string[] args)
    {
        var app = new ComplexTerminal ();
        return app.run (args);
    }
}
