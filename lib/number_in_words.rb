class NumberInWords
  attr_accessor :number
  
  TEENS = {
    1 => 'one',
    2 => 'two',
    3 => 'three',
    4 => 'four',
    5 => 'five',
    6 => 'six',
    7 => 'seven',
    8 => 'eight',
    9 => 'nine',
    10 => 'ten',
    11 => 'eleven',
    12 => 'twelve',
    13 => 'thirteen',
    14 => 'fourteen',
    15 => 'fifteen',
    16 => 'sixteen',
    17 => 'seventeen',
    18 => 'eighteen',
    19 => 'nineteen'
  }

  TENS = {
    20 => 'twenty',
    30 => 'thirty',
    40 => 'forty',
    50 => 'fifty',
    60 => 'sixty',
    70 => 'seventy',
    80 => 'eighty',
    90 => 'ninety'
  }
  
  def initialize(number)
    @number = number
  end

  def hundreds_in_words(number)
    hundreds, tens_and_units = number.divmod(100)
    tens, units = tens_and_units.divmod(10)
    result = []

    result << "#{TEENS[hundreds]} hundred" if hundreds > 0
    
    if TEENS[tens_and_units]
      result << TEENS[tens_and_units]
    else
      result << "#{TENS[tens*10]}" if tens != 0
      result << "#{TEENS[units]}" if units != 0
    end
    
    result.join(" ")
  end

  def convert
    wyn = []
    
    milions, less_than_milion = @number.divmod(1000000)
    thousends, lest_than_thousend = less_than_milion.divmod(1000)

    wyn << hundreds_in_words(milions) << 'milions' if milions > 0
    wyn << hundreds_in_words(thousends) << 'thousand' if thousends > 0
    wyn << hundreds_in_words(lest_than_thousend) if lest_than_thousend > 0
    
    wyn.join(" ")
  end

end

