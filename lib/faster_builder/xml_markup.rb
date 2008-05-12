require "builder"
require "faster_builder"

class FasterBuilder::XmlMarkup < BlankSlate
  
  def initialize(options = {})
    @options = options
    @nodes   = [nil]
    @current_node = nil
  end
  
  def instruct!(type = :xml, attrs = {})
    raise Builder::IllegalBlockError, "Blocks are not allowed on XML instructions" if block_given?
    version  = attrs[:version]  || "1.0"
    encoding = attrs[:encoding] || "UTF-8"
    @doc = XML::Document.new(version)
    @doc.encoding = encoding
    @nodes[0] = @doc
    @instructed = true
  end
  
  def cdata!(data)
    (@current_node || @nodes) << XML::Node.new_cdata(data)
  end
  
  def comment!(comment)
    raise Builder::IllegalBlockError, "Blocks are not allowed on XML comments" if block_given?
    (@current_node || @nodes) << XML::Node.new_comment(comment)
  end
  
  def declare!(inst, *args, &block)
    raise NotImplementedError, "libxml-ruby doesn't support generating declarations"
  end
  
  def tag!(element, *options, &block)
    # create a new node and intialize it
    if options.first.is_a?(Hash)
      node = XML::Node.new(element)
      content = nil
      attrs = options.first
    else
      if options.first.is_a?(Symbol)
        node = XML::Node.new("#{element}:#{options.first}")
      else
        node = XML::Node.new(element)
        content = options.first
      end
      
      attrs = options[1] || {}
    end
    
    for attr, value in attrs
      node[attr.to_s] = value.to_s
    end
    
    (@current_node || @nodes) << node
    @current_node = node
    
    text!(content)
    
    if block
      if content
        raise ArgumentError, "XmlMarkup cannot mix a text argument with a block"
      else
        block.call(self)
      end
    end
    
    @current_node = @current_node.parent
    return target!
  end
  
  def target!
    if @instructed
      return @nodes.map { |n| n.to_s }.join("")
    else
      return @nodes[1..-1].map { |n| n.to_s }.join("")
    end
  end
  
  def text!(text)
    if text && @current_node
      @current_node << text
    end
  end
  alias_method :<<, :text!
  
  def method_missing(element, *options, &block)
    tag!(element, *options, &block)
  end
  
end

