

public class TerminalSetting
{
    public bool allow_bold { get; set; }
    public bool audible_bell { get; set; }

    public Gdk.RGBA? background_color { get; set; }
    public Gdk.RGBA? foreground_color { get; set; }
    public Gdk.RGBA[] palette { get; set; }

    public Gdk.RGBA? cursor_color { get; set; }
    public Vte.CursorShape cursor_shape { get; set; }
    public string encoding { get; set; }

    public string shell { get; set; }
    public string font { get; set; }

    public TerminalSetting.default ()
    {
        background_color = Gdk.RGBA ();
        foreground_color = Gdk.RGBA ();
        palette = new Gdk.RGBA[16];
        cursor_color = Gdk.RGBA ();

        allow_bold = true;
        audible_bell = false;

        background_color.parse ("#000000");
        foreground_color.parse ("#FFFFFF");

        palette[0].parse ("#000000");
        palette[1].parse ("#C00000");
        palette[2].parse ("#00C000");
        palette[3].parse ("#C0C000");
        palette[4].parse ("#0000C0");
        palette[5].parse ("#C000C0");
        palette[6].parse ("#00C0C0");
        palette[7].parse ("#C0C0C0");
        palette[8].parse ("#3F3F3F");
        palette[9].parse ("#FF3F3F");
        palette[10].parse ("#3FFF3F");
        palette[11].parse ("#FFFF3F");
        palette[12].parse ("#3F3FFF");
        palette[13].parse ("#FF3FFF");
        palette[14].parse ("#3FFFFF");
        palette[15].parse ("#FFFFFF");

        cursor_color.parse ("#FFFFFF");
        cursor_shape = Vte.CursorShape.BLOCK;
        encoding = "";

        shell = "";
        font = "";
    }

    public void apply (Vte.Terminal terminal)
    {
        terminal.allow_bold = allow_bold;
        terminal.audible_bell = audible_bell;

        terminal.set_colors (foreground_color, background_color, palette);

        terminal.set_color_cursor (cursor_color);
        terminal.cursor_shape = cursor_shape;

        Pango.FontDescription font_desc;
        if (font == "")
        {
            var sys_settings = new GLib.Settings ("org.gnome.desktop.interface");
            font_desc = Pango.FontDescription.from_string (sys_settings.get_string ("monospace-font-name"));
        }
        else
        {
            font_desc = Pango.FontDescription.from_string (font);
        }
        terminal.set_font (font_desc);
    }
}
