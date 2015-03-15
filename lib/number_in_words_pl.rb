class NumberInWordsPl
  attr_accessor :number
  
  TEENS = {
    1 => 'jeden',
    2 => 'dwa',
    3 => 'trzy',
    4 => 'cztery',
    5 => 'pięć',
    6 => 'sześć',
    7 => 'siedem',
    8 => 'osiem',
    9 => 'dziewięć',
    10 => 'dziesięć',
    11 => 'jedenaście',
    12 => 'dwanaście',
    13 => 'trzynaście',
    14 => 'czternaście',
    15 => 'piętnaście',
    16 => 'szesnaście',
    17 => 'siedemnascie',
    18 => 'osiemnaście',
    19 => 'dźiewiętnaście'
  }

  TENS = {
    20 => 'dwadzieścia',
    30 => 'trzydzieści',
    40 => 'czterdzieści',
    50 => 'pięćdziesiąt',
    60 => 'sześćdziesiąt',
    70 => 'siedemdziesiąt',
    80 => 'osiemdziesiąt',
    90 => 'dziewięćdziesiąt'
  }

  THOUSENDS = {
    100 => 'sto',
    200 => 'dwieście',
    300 => 'trzysta',
    400 => 'czterysta',
    500 => 'pięćset',
    600 => 'sześćset',
    700 => 'siedemset',
    800 => 'osiemset',
    900 => 'dziewięćset'
  }

  
  def initialize(number)
    @number = number
  end

  def hundreds_in_words(number)
    raise "Number should be in 1..999, was: #{number}" unless (1..999).member?(number)
    hundreds, tens_and_units = number.divmod(100)
    tens, units = tens_and_units.divmod(10)
    result = []
    result << "#{THOUSENDS[hundreds*100]}" if hundreds > 0
    if TEENS[tens_and_units]
      result << TEENS[tens_and_units]
    else
      result << "#{TENS[tens*10]}" if tens != 0
      result << "#{TEENS[units]}" if units != 0
    end

    result.join(" ")
  end

  def convert
    result = []
    
    milions, less_than_milion = @number.divmod(1000000)
    thousends, lest_than_thousend = less_than_milion.divmod(1000)

    case milions
    when 1
      result << 'milion'
    when 2..4
      result << hundreds_in_words(milions) << 'miliony'
    when 5..999
      result << hundreds_in_words(milions) << 'milionów'
    end
    
    case thousends
    when 1
      result << 'tysiąc'
    when 2..4
      result << hundreds_in_words(thousends) << 'tysiące'
    when 5..999
      result << hundreds_in_words(thousends) << 'tysięcy'
    end

    if lest_than_thousend > 0
      result << hundreds_in_words(lest_than_thousend)
    end

    result.join(" ")
  end
end

