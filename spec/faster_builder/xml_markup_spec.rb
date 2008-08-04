require File.join(File.dirname(__FILE__), "..", "spec_helper")

require "faster_builder/xml_markup"

describe FasterBuilder::XmlMarkup do
  
  before(:each) do
    @xml = FasterBuilder::XmlMarkup.new
  end
  
  it "should handle nested elements" do
    @xml.blort do
      @xml.squawk("moo")
      @xml.shiv do
        @xml.heehaw(:ptang => :dinky)
      end
    end
    @xml.target!.should == %{<blort>\n  <squawk>moo</squawk>\n  <shiv>\n    <heehaw ptang="dinky"/>\n  </shiv>\n</blort>}
  end
  
  it "should handle nested builders" do
    # TODO: implement nested builders
    pending("some sort of target implementation")
    x = FasterBuilder::XmlMarkup.new(:target => @xml)
    @xml.ref(:id=>:"H&amp;R") {
      x.element(:tag=>"Long&Short")
    }
    @xml.target!.should ==  %{<ref id="H&amp;R"><element tag="Long&amp;Short"/></ref>}
  end
  
  it "should pass in a reference to the builder to all blocks" do
    @xml.dingo do |d|
      d.chubby("bunny")
    end
    @xml.target!.should == %{<dingo>\n  <chubby>bunny</chubby>\n</dingo>}
  end
  
  it "should handle multiple attributes per element" do
    @xml.ref(:id => 12, :name => "bill")
    @xml.target!.should match(%r{^<ref( id="12"| name="bill"){2}/>$})
  end
  
  it "should handle attributes and text" do
    @xml.a("link", :href=>"http://onestepback.org")
    @xml.target!.should == %{<a href="http://onestepback.org">link</a>}
  end
  
  it "should handle complex tag/element arrangements" do
    @xml.body(:bg=>"#ffffff") { |x|
      x.title("T", :style=>"red")
    }
    @xml.target!.should == %{<body bg="#ffffff">\n  <title style="red">T</title>\n</body>}
  end
  
  it "should deal with funky symbols" do
    @xml.tag!("non-ruby-token", :id=>1) { |x| x.ok }
    @xml.target!.should == %{<non-ruby-token id="1">\n  <ok/>\n</non-ruby-token>}
  end
  
  it "should be able to handle tags with the same names as private methods" do
    @xml.tag!("loop", :id=>1) { |x| x.ok }
    @xml.target!.should == %{<loop id="1">\n  <ok/>\n</loop>}
  end
  
  it "should not have explicit markers" do
    @xml.p { |x| x.b("HI") }
    @xml.target!.should == "<p>\n  <b>HI</b>\n</p>"
  end
  
  it "should allow for local variable references" do
    n = 3
    @xml.ol { |x| n.times { x.li(n) } }
    @xml.target!.should == "<ol>\n  <li>3</li>\n  <li>3</li>\n  <li>3</li>\n</ol>"
  end
  
  def name
    "bob"
  end
  
  it "should allow for method references" do
    @xml.title { |x| x.a { x.b(name) } }
    @xml.target!.should == "<title>\n  <a>\n    <b>bob</b>\n  </a>\n</title>"
  end

  it "should allow text to be appended" do
    @xml.p { |x| x.br; x.text!("HI") }
    @xml.target!.should == "<p><br/>HI</p>"
  end
  
  it "should raise an ArgumentError with ambiguous markup" do
    proc { @xml.h1("data1") { b } }.should \
      raise_error(ArgumentError, "XmlMarkup cannot mix a text argument with a block")
  end
  
  it "should work with capitalized element names" do
    @xml.P { |x| x.B("hi"); x.BR(); x.EM { x.text! "world" } }
    @xml.target!.should == "<P>\n  <B>hi</B>\n  <BR/>\n  <EM>world</EM>\n</P>"
  end
  
  it "should escape element contents" do
    @xml.div { |x| x.text! "<hi>"; x.em("H&R Block") }
    @xml.target!.should == %{<div>&lt;hi&gt;<em>H&amp;R Block</em></div>}
  end
  
  it "should return itself as a string" do
    str = @xml.x("men")
    @xml.target!.should == str
  end
  
  describe "escaping XML content" do
    
    it "should properly escape element contents" do
      @xml.munge("&&&&&&<><><><boosh")
      @xml.target!.should == %{<munge>&amp;&amp;&amp;&amp;&amp;&amp;&lt;&gt;&lt;&gt;&lt;&gt;&lt;boosh</munge>}
    end
    
    it "should properly escape attribute values" do
      @xml.munge("blah" => "&gh\"g>")
      @xml.target!.should == %{<munge blah="&amp;gh&quot;g&gt;"/>}
    end
    
    it "should escape < characters in element contents" do
      @xml.title("1<2")
      @xml.target!.should == "<title>1&lt;2</title>"
    end
    
    it "should escape < characters in attribute values" do
      @xml.a(:title => "1<2")
      @xml.target!.should == %{<a title="1&lt;2"/>}
    end
    
    it "should escape ampersands in element contents" do
      @xml.title('AT&T')
      @xml.target!.should == '<title>AT&amp;T</title>'
    end
    
    it "should escape ampersands in attribute values" do
      @xml.a(:title => 'AT&T')
      @xml.target!.should == '<a title="AT&amp;T"/>'
    end
    
    it "should escape ampersand entities in element contents" do
      @xml.title('&amp;')
      @xml.target!.should == '<title>&amp;amp;</title>'
    end
    
    it "should escape ampersand entities in attribute values" do
      @xml.a(:title => '&amp;')
      @xml.target!.should == %{<a title="&amp;amp;"/>}
    end
    
    it "should escape > characters in element contents" do
      @xml.title("2>1")
      @xml.target!.should == "<title>2&gt;1</title>"
    end
    
    it "should escape > characters in attribute values" do
      @xml.a(:title => '2>1')
      @xml.target!.should == '<a title="2&gt;1"/>'
    end
    
    it "should escape double quotes in attribute values" do
      @xml.a(:title => '"x"')
      @xml.target!.should == '<a title="&quot;x&quot;"/>'
    end
    
    it "should escape directly appended text" do
      @xml.div { |x| x << "<h&i>"; x.em("H&R Block") }
      @xml.target!.should == "<div>&lt;h&amp;i&gt;<em>H&amp;R Block</em></div>"
    end
    
    it "should not double-escape content" do
      # TODO: figure out how to not double-escape content
      pending("an entity decoder")
      @xml.sample(:escaped=>"This&That", :unescaped=>:"Here&amp;There")
      @xml.target!.should == %{<sample escaped="This&amp;That" unescaped="Here&amp;There"/>}
    end
    
    it "should escape symbolize attributes" do
      @xml.ref(:id => :"H&amp;R")
      @xml.target!.should == %{<ref id="H&amp;amp;R"/>}
    end
    
  end
  
  describe "generating namespaced XML" do
    
    it "should accept namespaced elements" do
      @xml.tag!("esi:include", :src => "ninja!")
      @xml.target!.should == %{<esi:include src="ninja!"/>}
    end
    
    it "should generate simple namespaces" do
      @xml.rdf :RDF
      @xml.target!.should == "<rdf:RDF/>"
    end
    
    it "should generate more complicated namespaces" do
      xml = Builder::XmlMarkup.new(:indent=>2)
      xml.instruct!
      xml.rdf :RDF, 
        "xmlns:rdf" => :"&rdf;",
        "xmlns:rdfs" => :"&rdfs;",
        "xmlns:xsd" => :"&xsd;",
        "xmlns:owl" => :"&owl;" do
        xml.owl :Class, :'rdf:ID'=>'Bird' do
          xml.rdfs :label, 'bird'
          xml.rdfs :subClassOf do
            xml.owl :Restriction do
              xml.owl :onProperty, 'rdf:resource'=>'#wingspan'
              xml.owl :maxCardinality,1,'rdf:datatype'=>'&xsd;nonNegativeInteger'
            end
          end
        end
      end
      xml.target!.should match(/^<\?xml/)
      xml.target!.should match(/\n<rdf:RDF/m)
      xml.target!.should match(/xmlns:rdf="&rdf;"/m)
      xml.target!.should match(/<owl:Restriction>/m)
    end
    
  end
  
  describe "generating special markup" do
    
    it "should optionally add an XML prolog" do
      @xml.puppies("yay")
      @xml.target!.should == "<puppies>yay</puppies>"
      @xml.instruct!
      @xml.target!.should == %{<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<puppies>yay</puppies>}
    end
    
    it "should add XML comments" do
      @xml.bob do
        @xml.comment!("The flavor is too strong.")
      end
      @xml.target!.should == %{<bob>\n<!--The flavor is too strong.-->\n</bob>}
    end
    
    it "should add CDATA sections" do
      @xml.bob do
        @xml.cdata!("You can't stop it.")
      end
      @xml.target!.should == %{<bob><![CDATA[You can't stop it.]]></bob>}
    end
    
    it "should not escape the content of CDATA sections" do
      @xml.bob do
        @xml.cdata!("The flavor's too strong & you can't stop it.")
      end
      @xml.target!.should == %{<bob><![CDATA[The flavor's too strong & you can't stop it.]]></bob>}
    end
    
    it "should generate comments" do
      @xml.comment!("COMMENT")
      @xml.target!.should == "<!--COMMENT-->"
    end
    
    it "should indent comments" do
      @xml.p { @xml.comment! "OK" }
      @xml.target!.should == "<p>\n<!--OK-->\n</p>"
    end
    
    it "should generate non-XML prologs" do
      # TODO: find out how to generate non-XML prologs with libxml-ruby
      pending("some changes to libxml-ruby")
      @xml.instruct! :abc, :version=>"0.9"
      @xml.target!.should == "<?abc version=\"0.9\"?>\n"
    end
    
    it "should NOT generate nested XML prologs" do
      @xml.p { @xml.instruct! :xml }
      @xml.target!.should == %{<?xml version="1.0" encoding="UTF-8"?>\n<p/>}
    end
    
    it "should generate non-XML prologs without attributes" do
      pending("some changes to libxml-ruby")
      @xml.instruct! :zz
      @xml.target!.should == "<?zz?>\n"
    end
    
    it "should generate standard XML prologs" do
      @xml.instruct!
      @xml.target!.should == %{<?xml version="1.0" encoding="UTF-8"?>\n}
    end
    
    it "should generate XML with different encodings" do
      @xml.instruct! :xml, :encoding => "UCS-2"
      @xml.target!.should == "\377\376<\000?\000x\000m\000l\000 \000v\000e\000r\000s\000i\000o\000n\000=\000\"\0001\000.\0000\000\"\000 \000e\000n\000c\000o\000d\000i\000n\000g\000=\000\"\000U\000C\000S\000-\0002\000\"\000?\000>\000\n\000"
    end
    
    it "should generate standalone XML prologs" do
      # TODO: find out how to create standalone XML documents with libxml-ruby
      pending("some changes to libxml-ruby")
      @xml.instruct! :xml, :standalone => "yes"
      @xml.target!.should == %{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n}
    end
    
    it "should raise an IllegalBlockError if elements are nested in a prolog" do
      proc { @xml.instruct! { |x| x.hi } }.should raise_error(Builder::IllegalBlockError)
    end
    
    it "should raise an IllegalBlockError if elements are nested in a comment" do
      proc { @xml.comment!(:element) { |x| x.hi } }.should raise_error(Builder::IllegalBlockError)
    end
    
  end
  
  describe "generating declarations" do
    
    # TODO: figure out how to generate declarations with libxml-ruby
    
    it "should generate declarations" do
      pending("libxml-ruby support for declarations")
      @xml.declare! :element
      @xml.target!.should == %{<!element>}
    end
    
    it "should include bare arguments" do
      pending("libxml-ruby support for declarations")
      @xml.declare! :element, :arg
      @xml.target!.should == %{<!element arg>}
    end
    
    it "should include quoted argments" do
      pending("libxml-ruby support for declarations")
      @xml.declare! :element, "string"
      @xml.target!.should == %{<!element "string">}
    end
    
    it "should include mixed argments" do
      pending("libxml-ruby support for declarations")
      @xml.declare! :element, :x, "y", :z, "-//OASIS//DTD DocBook XML//EN"
      @xml.target!.should == %{<!element x "y" z "-//OASIS//DTD DocBook XML//EN">}
    end
    
    it "should generate nested declarations" do
      pending("libxml-ruby support for declarations")
      @xml.declare! :DOCTYPE, :chapter do |x|
        x.declare! :ELEMENT, :chapter, "(title,para+)".intern
      end
      @xml.target!.should == %{<!DOCTYPE chapter [<!ELEMENT chapter (title,para+)>]>}
    end
    
    it "should generate complex declarations" do
      pending("libxml-ruby support for declarations")
      @xml.declare! :DOCTYPE, :chapter do |x|
        x.declare! :ELEMENT, :chapter, "(title,para+)".intern
        x.declare! :ELEMENT, :title, "(#PCDATA)".intern
        x.declare! :ELEMENT, :para, "(#PCDATA)".intern
      end
      expected = %{<!DOCTYPE chapter [
  <!ELEMENT chapter (title,para+)>
  <!ELEMENT title (#PCDATA)>
  <!ELEMENT para (#PCDATA)>
]>
      }
      @xml.target!.should == expected
    end
    
  end
  
end