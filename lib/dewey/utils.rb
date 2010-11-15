module Dewey
  module Utils #:nodoc:
    # Perform string escaping for Atom slugs
    def slug(string)
      string.chars.to_a.map do |char|
        decimal = char.unpack('U').join('').to_i
        if decimal < 32 || decimal > 126 || decimal == 37
          char = "%#{char.unpack('H2').join('%').upcase}"
        end

        char
      end.join('')
    end

    module_function :slug
  end
end
