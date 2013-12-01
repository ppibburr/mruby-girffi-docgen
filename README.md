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

YARD Output
===
```ruby
    # ...

    # webkit_favicon_database_get_favicon_pixbuf
    #
    # @param [String] page_uri 
    # @param [Integer] width 
    # @param [Integer] height 
    # @param [Gio::Cancellable] cancellable  defaults to `nil`
    # @yieldparam [GObject::Object] source_object
    # @yieldparam [FFI::Pointer] res
    # @yieldreturn [void] 
    # @return [NilClass] 
    def get_favicon_pixbuf(page_uri,width,height,cancellable = nil)
    end
    
    # ...
```
