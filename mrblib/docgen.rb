class DocGen
  BUFFER = []

  def self.ffi_type2ruby t
    if [:int,:int8,:int16,:int32,:int64,:uint,:uint8,:uint16,:uint32,:uint64,:size_t].index(t)
      return Integer
    elsif t == :utf8
      return String
    elsif t == :double or t == :float
      return Float
    elsif t == :string
      return String  
  
    elsif t == :bool
      return "Boolean"
    elsif t == :void
      return "void"
    else
      return FFI::Pointer
    end
  end

  class Iface
    def initialize q
      @q = q
    end
    
    def puts str
      DocGen::BUFFER << str
    end
  
    def document
      puts "module #{@q.data.namespace}"
      puts "  class #{@q.data.name}"
    
      @q.data.get_methods.each do |m|
        if m.method?
          document_instance_method(m)
        else
          document_class_method(m)
        end
      end
      
      puts "  end"
      puts "end"
    end
    
    def document_method(m, takes_self=false)
      rm = @q.girffi_instance_method(m.name.to_sym)
      puts "    # #{m.symbol}"
      aa = []
      h=rm.arguments
      h.keys.sort.each do |k|
        arg = m.arg(h[k])
        aa << "c_param_#{h[k]}"
        
        if arg.argument_type.tag == :array
          atype = "Array<#{DocGen.ffi_type2ruby(arg.argument_type.element_type.get_ffi_type())}>"
        else
          if arg.argument_type.flattened_tag == :object
            atype = ::Object.const_get(ns=arg.argument_type.interface.namespace.to_sym).const_get(n=arg.argument_type.interface.name.to_sym)
          else
            atype = DocGen.ffi_type2ruby(arg.argument_type.get_ffi_type())
          end
        end
        
        puts "    # @param c_param_#{h[k]} [#{atype}]"
      end
      returns = rm.returns.map do |r| 
        unless r.respond_to? :tag
          r = r.argument_type
        end
      
        if r.tag == :array
          rtype = "Array<#{DocGen.ffi_type2ruby(r.element_type.get_ffi_type())}>"
        else
          if r.flattened_tag == :object
            rtype = ::Object.const_get(ns=r.interface.namespace.to_sym).const_get(n=r.interface.name.to_sym)
          else
            rtype = DocGen.ffi_type2ruby(r.get_ffi_type())
          end
        end
        
        rtype
      end
      
      if !returns.empty?
        if returns.length > 1
          returns.delete("void")
          puts "    # @return [Array<#{returns.join(", ")}>]"
        else
          puts "    # @return [#{returns[0]}]"
        end
      else
        puts "    # @return [NilClass]"
      end
      puts "    def #{m.name}(#{aa.join(", ")})"   
      puts "    end"
      puts "\n"
    end
    
    def document_instance_method m
      document_method m,true
    end
    
    def document_class_method m
      document_method m
    end
  end
  
  class Class < Iface
  
  end
  
  def document q
  
  end
end

GirFFI::setup :Gdk
GirFFI::setup :GdkPixbuf
GirFFI::setup :Gtk
p Gdk::WindowEdge
dgc = DocGen::Class.new(Gtk::Window)
dgc.document()
GLib::File.set_contents("out.rb",DocGen::BUFFER.join("\n"))
