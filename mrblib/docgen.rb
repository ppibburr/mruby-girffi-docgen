class DocGen
  BUFFER = []

  def self.ffi_type2ruby t
    if [:int,:int8,:int16,:int32,:int64,:uint,:uint8,:uint16,:uint32,:uint64,:size_t,:long,:ulong].index(t)
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
  
  def self.ruby_type t
    if t.respond_to?(:argument_type)
      t = t.argument_type
    end
   
    if t.interface.is_a?(GObjectIntrospection::IEnumInfo)
      return Integer,desc = " a member of enum #{t.interface.namespace}::#{t.interface.name}"
    end
    
    if t.interface.is_a?(GObjectIntrospection::IObjectInfo)
      desc = ""
    end
    
    if t.interface.is_a?(GObjectIntrospection::IFlagsInfo)
      return Integer,desc = " a member of enum #{t.interface.namespace}::#{t.interface.name}"
    end    
    
    if t.interface.is_a?(GObjectIntrospection::IConstantInfo)
      desc = " #{t.interface.namespace}::#{t.interface.name}"
    end
    
    if t.flattened_tag == :object
      rt = "#{t.interface.namespace}::#{t.interface.name}"
    else
    
      if t.tag == :array
        rt = "Array<#{ffi_type2ruby(t.element_type)}>"
      else
        rt = ffi_type2ruby(t.get_ffi_type)
      end
    end
   
  
    return rt,desc
  end

  class Iface
    def initialize q
      @q = q
      @buffer = []
    end
    
    def puts str
      @buffer << str
    end
  
    def document
      puts "module #{@q.data.namespace}"
      puts "  class #{@q.data.name} < #{@q.superclass}"
    
      @q.data.get_methods.each do |m|
        if m.method?
          document_instance_method(m)
        else
          document_class_method(m)
        end
      end
      
      puts "  end"
      puts "end"
      
      GLib::File.set_contents("#{@q.data.namespace}_#{@q.data.name}.rb",@buffer.join("\n"))   
      @buffer = []   
    end
    
    def document_method(m, takes_self=false)
      rm = @q.girffi_instance_method(m.name.to_sym)
     
      puts "    # #{m.symbol}"
     
      aa = []
      h=rm.arguments
     
      h.keys.sort.each do |k|
        arg = m.arg(h[k])
        aa << "c_param_#{h[k]}"
        
        atype,desc = DocGen::ruby_type(arg)
        
        puts "    # @param [#{atype}] c_param_#{h[k]} #{desc}"
      end
     
      returns = rm.returns.map do |r|
        DocGen::ruby_type(r)
      end
      
      if rm.throws?
        puts "    # @raise [GLib::Error] the error"
      end
      
      if returns[0] and returns[0][0] == "void"
        returns.shift
      end
      
      if !returns.empty?
        if returns.length < 2
          puts "    # @return [#{returns[0][0]}]#{returns[0][1]}"
        else
          v = returns.map do |r| r[0] end.join(", ")
          puts "    # @return [Array<#{v}>]"
        end
      else
        puts "    # @return [NilClass]"
      end
      
      if rm.takes_block?
        aa << "&b"
      end
      
      return aa
    end
    
    def document_instance_method m
      aa=document_method m,true
      puts "    def #{m.name}(#{aa.join(", ")})"   
      puts "    end"
      puts "\n"      
    end
    
    def document_class_method m
      aa=document_method m
      puts "    def self.#{m.name}(#{aa.join(", ")})"   
      puts "    end"
      puts "\n"      
    end
  end
  
  class Class < Iface
  
  end
  
  attr_reader :namespace
  def initialize ns
    @namespace = ns
  end
  
  def document()
    GirFFI::REPO.infos("#{namespace}").find_all do |i|
      i.is_a?(GObjectIntrospection::IObjectInfo)
    end.each do |q| 
      dgc = DocGen::Class.new(namespace.const_get(q.name.to_sym))
      dgc.document()
    end 
  end
end


## Example of documenting Gtk
## outputs to ./Gtk_<ObjectName>.rb
## for all the GObjectIntrospection::IObjectInfo's


## Ensure all the namespaces are loaded
# GirFFI::setup :Pango
# GirFFI::setup :Atk
# GirFFI::setup :Gdk
# GirFFI::setup :GdkPixbuf

## Setup Gtk
# GirFFI::setup :Gtk

## Document it
# dg = DocGen.new(Gtk)
# dg.document()


