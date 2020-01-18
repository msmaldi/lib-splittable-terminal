project ('splittable-terminal', [ 'vala', 'c' ], version: '1.0.0')

gee = dependency('gee-0.8')
glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')
gtk = dependency('gtk+-3.0')
vte = dependency('vte-2.91')

splittable_terminal_deps = [
    gee,
    glib,
    gobject,
    gtk,
    vte
]

splittable_terminal_sources = [
    'src/Paned.vala',
    'src/Parser.vala',
    'src/Terminal.vala',
    'src/Workspace.vala',
]

include_dir = join_paths(
    get_option('prefix'),
    get_option('includedir')
)

splittable_terminal_static = static_library(
    meson.project_name(),
    splittable_terminal_sources,
    dependencies: splittable_terminal_deps,
    vala_header: 'terminal-widget.h',
    vala_vapi: 'terminal-widget.vapi',
    install: true,
    install_dir: [ true, include_dir, true ]
)

splittable_terminal_dependency = declare_dependency (
    link_with: splittable_terminal_static,
    dependencies: splittable_terminal_deps,
    include_directories: [ include_directories('.') ]
)

subdir('samples')
subdir('test')