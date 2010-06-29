module Dewey
  module Utils #:nodoc:
    # Performs URI escaping. (Stolen from Camping via Rake).
    def escape(s)
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
        '%'+$1.unpack('H2' * bytesize($1)).join('%').upcase
      }.tr(' ', '+')
    end
    
    module_function :escape
    
    # Return the bytesize of String; uses String#length under Ruby 1.8 and
     def bytesize(string)
       string.bytesize
     end
     
     module_function :bytesize
  end
end