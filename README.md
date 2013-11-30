mruby-girffi-docgen
===================

Generates YARD documentation for generated bindings

Example
===
```ruby
 # Example of documenting Gtk
 # outputs to ./Gtk_<ObjectName>.rb
 # for all the GObjectIntrospection::IObjectInfo's


 # Ensure all the namespaces are loaded
 GirFFI::setup :Pango
 GirFFI::setup :Atk
 GirFFI::setup :Gdk
 GirFFI::setup :GdkPixbuf

 # Setup Gtk
 GirFFI::setup :Gtk

 # Document it
 dg = DocGen.new(Gtk)
 dg.document()
```
