module OpenURL
  
  # The ContextObjectEntity is a generic class to define an entity.  It should
  # not be initialized directly, only through one of its children: 
  #   ReferentEntity, ReferrerEntity, ReferringEntity, ResolverEntity, 
  #   ServiceTypeEntity, or CustomEntity
  
  class ContextObjectEntity
    # identifiers should always be an array, but it might be an empty one. 
    attr_reader(:identifiers, :reference, :format, :metadata, :private_data, :abbr, :label)
    
    def initialize
      @identifiers = []
      @reference = {"format"=>nil, "location"=>nil}
      @format = nil
      @metadata = {}
      @private_data = nil
    end
    
    # Sets the location and format of a by-reference context object entity
    
    def set_reference(loc, fmt)
      @reference["location"] = loc
      @reference["format"] = fmt
    end

    # Should really be called "add identifier", since we can have more
    # than one. But for legacy, it's "set_identifier". 
    def add_identifier(val)
      @identifiers.push( self.class.normalize_id(val) )
    end
    alias :set_identifier :add_identifier
    
    # We can actually have more than one, but certain code calls this
    # method as if there's only one. We return the first. 
    def identifier
      return @identifiers[0]
    end
    
    
    def set_private_data(val)
      @private_data = val
    end  

    def set_metadata(key, val)
      @metadata[key] = val
    end
    
    def get_metadata(key)
      return @metadata[key]
    end
    
    def set_format(format)
      @format = format
    end  
    
    # Serializes the entity to XML and attaches it to the supplied REXML element.
    
    def xml(co_elem)      
      meta = {"container"=>co_elem.add_element("ctx:"+@label)}

      if @metadata.length > 0 or @format
        meta["metadata-by-val"] = meta["container"].add_element("ctx:metadata-by-val")
        if @format 
          meta["format"] = meta["container"].add_element("ctx:format")
          meta["format"].text = "info:ofi/fmt:xml:xsd:"+@format
        end
        if @metadata.length > 0
          meta["metadata"] = meta["metadata-by-val"].add_element("ctx:metadata")
          @metadata.each do |k,v|
            meta[k] = meta["metadata"].add_element("ctx:"+k)
            meta[k].text = v
          end
        end
      end
      if @reference["format"] 
        meta["metadata-by-ref"] = meta["container"].add_element("ctx:metadata-by-ref")
        meta["ref_format"] = meta["metadata-by-ref"].add_element("ctx:format")
        meta["ref_format"].text = @reference["format"]
        meta["ref_loc"] = meta["metadata-by-ref"].add_element("ctx:location")
        meta["ref_loc"].text = @reference["location"]          
      end
      
      @identifiers.each do |id|
        # Yes, meta["identifier"] will get over-written if there's more than
        # one identifier. But I dont' think this meta hash is used for much
        # I don't think it's a problem. -JR 
        meta["identifier"] = meta["container"].add_element("ctx:identifier")
        meta["identifier"].text = id
      end
      if @private_data
        meta["private-data"] = meta["container"].add_element("ctx:private-data")
        meta["private-data"].text = @private_data
      end          
      return co_elem
    end
    
    # Outputs the entity as a KEV array
    
    def kev
      kevs = []
      
      @metadata.each do |k,v|
        kevs << "#{@abbr}.#{k}="+CGI.escape(v) if v                      
      end
      
      kevs << "#{@abbr}_val_fmt="+CGI.escape("info:ofi/fmt:xml:xsd:#{@format}") if @format                  

      if @reference["format"] 
        kevs << "#{@abbr}_ref_fmt="+CGI.escape(@reference["format"])
        kevs << "#{@abbr}_ref="+CGI.escape(@reference["location"])      
      end
      
      @identifiers.each do |id| 
          kevs << "#{@abbr}_id="+CGI.escape(id)
      end
      
      kevs << "#{@abbr}_dat="+CGI.escape(@private_data) if @private_data
                    
      return kevs      
    end
    
    # Outputs the entity as a hash
    
    def to_hash
      co_hash = {}
      
      @metadata.each do |k,v|
        co_hash["#{@abbr}.#{k}"]=v if v
      end
      
      co_hash["#{@abbr}_val_fmt"]="info:ofi/fmt:xml:xsd:#{@format}" if @format              

      if @reference["format"] 
        co_hash["#{@abbr}_ref_fmt"]=@reference["format"]
        co_hash["#{@abbr}_ref"]=@reference["location"]
      end
      
      @identifiers.each do |id|
        # Put em in a list. 
        co_hash["#{@abbr}_id"] ||= Array.new
        co_hash["#{@abbr}_id"].push( id )
      end
      co_hash["#{@abbr}_dat"]=@private_data if @private_data
              
      return co_hash    
    end    
    
    # Checks to see if the entity has any metadata set.
    
    def empty?
      return false if (@identifiers.length > 0 ) or @reference["format"] or @reference["location"] or @metadata.length > 0 or @format or @private_data              
      return true      
    end
    
    # Serializes the metadata values for Referent and ReferringEntity entities
    # since their schema is a little different.
    
    def xml_for_ref_entity(co_elem)      
      meta = {"container"=>co_elem.add_element("ctx:"+@label)}

      if @metadata.length > 0 or @format
        meta["metadata-by-val"] = meta["container"].add_element("ctx:metadata-by-val")
        if @format 
          meta["format"] = meta["metadata-by-val"].add_element("ctx:format")
          meta["format"].text = "info:ofi/fmt:xml:xsd:"+@format

          if @metadata.length > 0
            meta["metadata"] = meta["metadata-by-val"].add_element("ctx:metadata")
            meta["format_container"] = meta["metadata"].add_element(@format)
            meta["format_container"].add_namespace(@abbr, meta["format"].text)
            meta["format_container"].add_attribute("xsi:schemaLocation", meta["format"].text+" http://www.openurl.info/registry/docs/info:ofi/fmt:xml:xsd:"+@format)          
            @metadata.each do |k,v|
              meta[k] = meta["format_container"].add_element(@abbr+":"+k)
              meta[k].text = v
            end
          end
        end
      end
      if @reference["format"] 
        meta["metadata-by-ref"] = meta["container"].add_element("ctx:metadata-by-ref")
        meta["ref_format"] = meta["metadata-by-ref"].add_element("ctx:format")
        meta["ref_format"].text = @reference["format"]
        meta["ref_loc"] = meta["metadata-by-ref"].add_element("ctx:location")
        meta["ref_loc"].text = @reference["location"]          
      end
      
      @identifiers.each do |id|
        # Yes, if there's more than one, meta["identifier"] will get
        # overwritten with last. I don't think this is a problem, cause
        # meta["identifier"] isn't used anywhere. 
        meta["identifier"] = meta["container"].add_element("ctx:identifier")
        meta["identifier"].text = id
      end
      if @private_data
        meta["private-data"] = meta["container"].add_element("ctx:private-data")
        meta["private-data"].text = @private_data
      end          
      return co_elem
    end  

    # Switch old 0.1 style ids to new 1.0 style ids.
    # Eg, turn << doi:[x] >>    into     << info:doi/[x] >>
    def self.normalize_id(value)
        # info, urn, and http are all good new style 1.0 ids.
        # we assume anything else is not. Is this a valid assumption?
        unless ( (value.slice(0,5) == 'info:') || 
          (value.slice(0,4) == 'urn:') || 
          (value.slice(0,5) == 'http:') )
          value = value.sub(/^([a-z,A-Z]+)\:/, 'info:\1/')
        end

        return value
    end
    
  end

  class ReferentEntity < ContextObjectEntity
    def initialize
      super()
      @abbr = "rft"
      @label = "referent"
    end
    def xml(co_elem)
      return self.xml_for_ref_entity(co_elem)
    end 
    def set_format(fmt) 
      if fmt.split(":").length > 1
        @format = fmt.split(":").last
      else
        @format = fmt
      end
    end
  end

  class ReferringEntity < ContextObjectEntity
    def initialize
      super()
      @abbr = "rfe"
      @label = "referring-entity"
    end
    def xml(co_elem)
      return self.xml_for_ref_entity(co_elem)
    end
    def set_format(fmt) 
      if fmt.split(":").length > 1
        @format = fmt.split(":").last
      else
        @format = fmt
      end
  	end    
  end

  class ReferrerEntity < ContextObjectEntity
    def initialize
      super()
      @abbr = "rfr"
      @label = "referrer"
    end
  end

  class RequestorEntity < ContextObjectEntity
    def initialize
      super()
      @abbr = "req"
      @label = "requestor"
    end
  end

  class ServiceTypeEntity < ContextObjectEntity
    def initialize
      super()
      @abbr = "svc"
      @label = "service-type"
    end
  end
  class ResolverEntity < ContextObjectEntity
    def initialize
      super()
      @abbr = "res"
      @label = "resolver"
    end
  end

  class CustomEntity < ContextObjectEntity
    attr_accessor :abbr, :label
    def initialize(abbr=nil, label=nil)
      super()
      unless abbr
        @abbr = "cus"
      else
        @abbr = abbr
      end
      unless label
        @label = @abbr
      else
        @abbr = label
      end

    end
  end
  
end
