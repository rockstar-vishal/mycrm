module Utility
  class << self
    def to_words(number)
      in_words = 0.0
      return number.to_f if number.to_i < 1000
      if number >= 1000.0 && number <= 99999.0
        in_words = "#{(number / 1000.0).round(2)} K"
      end
      if number >= 100000.0 && number <= 9999999.0
        in_words = "#{(number / 100000.0).round(2)} Lacs"
      end
      if number >= 10000000.0
       in_words = "#{(number / 10000000.0).round(2)} Crore"
     end
     return in_words
    end
  end
end