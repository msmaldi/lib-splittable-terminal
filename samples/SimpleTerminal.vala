using Gee;

public class SimpleTerminal : Gtk.Application
{

    public SimpleTerminal ()
    {
        Object(
            application_id: "com.github.msmaldi.simple-terminal",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate ()
    {
        var window = new Gtk.ApplicationWindow (this);
        window.set_default_size (1366, 700);

        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_application_prefer_dark_theme = true;

        var workspace = new Workspace();

        window.add (workspace);
        window.show_all ();
    }

    private static int main (string[] args)
    {
        var app = new SimpleTerminal ();
        return app.run (args);
    }
}