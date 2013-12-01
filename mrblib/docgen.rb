## Example of YARD output ...
#    # webkit_favicon_database_get_favicon_pixbuf
#    #
#    # @param [String] page_uri 
#    # @param [Integer] width 
#    # @param [Integer] height 
#    # @param [Gio::Cancellable] cancellable  defaults to `nil`
#    # @yieldparam [GObject::Object] source_object
#    # @yieldparam [FFI::Pointer] res
#    # @yieldreturn [void] 
#    # @return [NilClass] 
#    def get_favicon_pixbuf(page_uri,width,height,cancellable = nil)
#    end    
##

class Struct
  def self.new *o
    cls=Class.new(NHash)
    
    cls.class_eval do
      o.each do |m|
        define_method "#{m}=" do |v|
          self[m] = v
        end
        
        define_method m do
          self[m]
        end
      end
    end
    
    cls
  end
end

class NHash
  def initialize
    @hash = {}
  end


  
  def [] k
    @hash[k]
  end
  
  def []= k,v
    @hash[k] = v
  end
end

GirFFI::DEBUG[:VERBOSE] = 0==1

class DocGen
  module Output
    class Namespace < ::Struct.new(:name, :version, :functions, :interfaces)
      def initialize *o
        super
        
        self[:interfaces] = []
        self[:functions]  = []
      end
    end
    
    class Type < ::Struct.new(:name)
    
    end
    
    class Block < ::Struct.new(:parameters, :returns)
    
    end
    
    class Array < ::Struct.new(:types); end
    
    class Argument < ::Struct.new(:description, :name, :type, :array, :omit, :block)
    
    end
    
    class Return < ::Struct.new(:description, :type,:array)
    
    end
    
    ReturnOfNilClass = t = Type.new
    t[:name] = "NilClass"
    
    class Function < ::Struct.new(:name, :symbol, :arguments, :signature,:method,:constructor, :returns, :error)
      def initialize opts={}
        super()

        self[:signature] = []
        self[:arguments] = []
        
        if opts.is_a?(::Hash)
          if opts[:constructor]
            self[:constructor] = true
            
          elsif opts[:method]
            self[:method] = true
          end
        end
      end
      
      def is_method?()
        !!self[:method]
      end
      
      def is_constructor?()
        !!self[:constructor]
      end
    end
    
    class IFace < ::Struct.new(:name, :namespace, :functions)
      def initialize h, q
        super()
        h[:interfaces] << self
        self[:name] = q.data.name.to_sym
        self[:functions] = []
      end
    end
    
    class Class < ::Struct.new(:name, :namespace, :functions, :superclass)
      def initialize h, q
        super()
        
        h[:interfaces] << self
        self[:name] = q.data.name.to_sym
        self[:functions] = []
      end
    end
  end

  def self.ffi_type2ruby t
    if [:int,:int8,:int16,:int32,:int64,:uint,:uint8,:uint16,:uint32,:uint64,:size_t,:long,:ulong].index(t)
      return Integer
    elsif t == :utf8
      return String
    elsif t == :strv
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

  RESERVED = [
    "for",
    "while",
    "end",
    "do",
    "until",
    "loop",
    "unless",
    "if",
    "else",
    "elsif",
    "case",
    "break",
    "next",
    "when",
    "return"
  ]

  def self.safe_name(n)
    if RESERVED.index(n)
      return "#{n}_"
    end 
    
    return n
  end

  class Iface
    attr_reader :namespace, :output
    def initialize ns,q, type = DocGen::Output::IFace
      @namespace = ns
      @output = type.new(ns,q)
      @q = q
    end
  
    def document
      print("\rExtracting #{@q}..."+(" "*40))
      @q.data.get_methods.each do |m|
        print("\rExtracting #{@q}")
        if m.method?
          print("##{m.name}."+(" "*40))
          document_instance_method(m)
        else
          print(".#{m.name}."+(" "*40))
          document_class_method(m)
        end
      end
      print("\r Extracted #{@q}"+(" "*40)+"\n")
    end
    
    def document_method(m, takes_self=false)
      if takes_self
        rm = @q.girffi_instance_method(m.name.to_sym)
        method = DocGen::Output::Function.new(:method=>true)
      else
        rm = @q.girffi_method(m.name.to_sym)
        
        bool = m.constructor?
        
        method = DocGen::Output::Function.new(:constructor=>bool)
      end
      
      m.extend GirFFI::Builder::MethodBuilder::Callable
      
      method[:name] = m.name.to_sym
      method[:symbol] = m.symbol
      method[:signature] = m.get_signature
      
      @output[:functions] << method
  
      aa = []
      h=rm.arguments
     
      h.keys.sort.each do |k|
        arg = m.arg(k)
        aa << n=DocGen::safe_name(arg.name)
        
        argument = Output::Argument.new()        
        
        argument[:name] = n
        
        argument[:omit] = !!arg.may_be_null?
        
        if arg.argument_type.tag == :array
          argument[:type] = :array
          at = argument[:array] = Output::Array.new
          at[:types] = [DocGen::ffi_type2ruby(arg.argument_type.flattened_array_type)]
        else
          atype,desc = DocGen::ruby_type(arg)
          
          t = argument[:type] = Output::Type.new
          t[:name] = atype
          argument[:description] = desc
        end
        
        method[:arguments] << argument        
      end
     
      returns = rm.returns.map do |r|
        DocGen::ruby_type(r)
      end
      
      if rm.throws?
        method[:error] = true
      end
      
      if returns[0] and returns[0][0] == "void"
        returns.shift
      end
      
      if rm.takes_block?
        method[:arguments] << a=Output::Argument.new()
        a[:name] = "b"
        a[:block] = b = Output::Block.new
        aaa = m.args
        cb = aaa.find do |a| a.closure >= 0 end
        info = m.arg(aaa.index(cb)).argument_type.interface
        info.extend GirFFI::Builder::MethodBuilder::Callable
        yptypes, yrt = info.get_signature
        ft = GirFFI::FunctionTool.new(info) do end
        take = []
        bbb = info.args
        bbb.each_with_index do |w,i|
          if w.name == "user_data"
            take << i
            next
          end
          
          len = w.argument_type.array_length
          take << len if len <= 0
        end;
        
        ylds = []
        bbb.each_with_index do |w, i|
          ylds << w unless take.index(i)
        end
        
        b[:parameters] = ylds.map do |pt|
          prm = Output::Argument.new()
          prm[:name] = pt.name
          
          if pt.argument_type.tag == :array
            prm[:type] = :array
            prm[:array] = pa = Output::Array.new
            pa[:types] = [DocGen::ffi_type2ruby(prm.argument_type.flattened_array_type)]
          else
            qq = DocGen.ruby_type(pt)
            prm[:type] = qq[0]
            prm[:description] = qq[1]
          end
          
          prm
        end
        
        yrt = b[:returns] = Output::Return.new
        yrtd = DocGen::ruby_type(info.return_type)
        yrtt = yrt[:type] = Output::Type.new
        yrtt[:name] = yrtd[0]
        yrt[:description] = yrtd[1]
        
        
        t=a[:type] = Output::Type.new
        t[:name] = "Proc"
        a[:description] = "The block to call" 
      end
      
      ret = method[:returns] = DocGen::Output::Return.new
      
      if returns.length > 1
        ret[:type] = :array
        a = ret[:array] = Output::Array.new
        a[:types] = returns.map do |t,d|
          o = Output::Type.new
          o[:name] = t
          next o
        end
        
      elsif returns.length == 1
        t = ret[:type] = DocGen::Output::Type.new
        t[:name] = returns[0][0]

        ret[:description] = returns[0][1]
      
      else
        ret[:type] = DocGen::Output::ReturnOfNilClass
      end
    end
    
    def document_instance_method m
      aa=document_method m,true     
    end
    
    def document_class_method m
      aa=document_method m      
    end
  end
  
  class Class < Iface
    def initialize ns,q,type = DocGen::Output::Class
      super ns,q,type
      @output[:superclass] = q.superclass.to_s
    end
  end
  
  attr_reader :namespace
  def initialize ns
    @namespace = Output::Namespace.new
    namespace.name = ns.to_s
  end
  
  def document()
    GirFFI::REPO.infos("#{namespace[:name]}").find_all do |i|
      i.is_a?(GObjectIntrospection::IObjectInfo)
    end.each do |q| 
      dgc = DocGen::Class.new(namespace,::Object.const_get(namespace[:name]).const_get(q.name.to_sym))
      dgc.document()
    end 
    
    return @namespace
  end
end

 
module YARDGenerator
  def self.puts s
    @buffer << s
  end
  
  def self.generate(ns)
    ns[:interfaces].each do |i|
      @buffer = []
      
      puts "module #{ns[:name]}"
      puts "  class #{i[:name]} < #{i[:superclass]}"
  
      i[:functions].each do |m|
        puts "    # #{m[:symbol]}"
        puts "    #"

        m[:arguments].each do |a|
          default = ""
          if a[:omit]
            default = " defaults to `nil`" 
          end
          unless a[:array]
            puts "    # @param [#{a[:type][:name]}] #{a[:name]} #{a[:description]}#{default}" unless a[:block]
            if a[:block]
              a[:block][:parameters].each do |prm|
                puts "    # @yieldparam [#{prm[:type]}] #{prm[:name]}"
              end
              
              puts "    # @yieldreturn [#{a[:block][:returns][:type][:name]}] #{a[:block][:returns][:description]}"
            end
          else
            puts "    # @param [Array<#{a[:array][:types].join(", ")}>] #{a[:name]}#{default}"
          end
        end

        unless m[:returns][:array]
          puts "    # @return [#{m[:returns][:type][:name]}] #{m[:returns][:description]}"
        else
          rtypes = m[:returns][:array][:types].map do |t| t[:name] end
          puts "    # @return [Array<#{rtypes.join(", ")}>]"
        end

        ins = ""
        ins = "self." if m.is_constructor?

        args = m.arguments.map do |a|
           default = ""
           if a[:omit]
             default = " = nil"
           end
           
           n = a[:name]
           if a[:block]
             next nil
           end
           
          "#{n}#{default}"
        end
        args.delete(nil)
        args=args.join(",")
        
        puts "    def #{ins}#{m[:name]}(#{args})"
        puts "    end"
        puts ""
      end
      
      puts "  end"
      puts "end"
      puts ""
      
      out = "#{ns[:name]}_#{i[:name]}.rb".downcase
      print "\rGenerating #{out} ..."+(" "*30)
      GLib::File.set_contents(out,@buffer.join("\n"))
    end
    print("\rComplete."+(" "*60)+"\n")
  end
end


