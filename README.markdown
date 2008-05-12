FasterBuilder
=============

Differences from Builder::XmlMarkup
-----------------------------------

  * Does not allow for unescaped text to be appended to element contents:

      xml.dip do
        xml << "<blorp>"
      end
      xml.target! #=> "<dip>&lt;blorp&gt;</dip>" instead of <dip><blorp></dip>
  
    This is a security/validity issue and isn't going to change.

  * Does not allow XML prologs to be inserted in the middle of the document:
  
      xml.dip do
        xml.instruct!
      end
      xml.target! #=> '<?xml version="1.0" encoding="UTF-8"?>\n<dip/>'
    
    This is a security/validity issue and isn't going to change.
    
  * Does not allow for unescaped symbol attribute values:
    
      xml.dingo(:name => :"SUPA<<FREAK")
      xml.target! #=> '<dingo name="SUPA&lt;&lt;FREAK"/>'
    
    This is a security/validity issue and isn't going to change.

  * Doesn't detect and avoid double-escaping. (I'm working on this.)
  * Doesn't generate declarations. (I'm working on this.)
  * Doesn't generate non-XML prologs. (I'm working on this.)
  * Doesn't generate standalone XML prologs. (I'm working on this.)
  * Doesn't support indentation options. (I'm working on this.)