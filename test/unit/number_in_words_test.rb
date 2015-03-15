require File.dirname(__FILE__) + '/../test_helper'

class NumberInWordsTest < ActiveSupport::TestCase

  should 'convert unity' do
    in_words = NumberInWords.new(1)
    assert_equal "one", in_words.convert
    in_words.number = 3
    assert_equal "three", in_words.convert
    in_words.number = 5
    assert_equal "five", in_words.convert
    in_words.number = 7
    assert_equal "seven", in_words.convert
    in_words.number = 9
    assert_equal "nine", in_words.convert
    in_words.number = 12
    assert_equal "twelve", in_words.convert
    in_words.number = 15
    assert_equal "fifteen", in_words.convert
  end

  should 'convert decimal' do
    in_words = NumberInWords.new(21)
    assert_equal "twenty one", in_words.convert
    in_words.number = 34
    assert_equal "thirty four", in_words.convert
    in_words.number = 52
    assert_equal "fifty two", in_words.convert
    in_words.number = 68
    assert_equal "sixty eight", in_words.convert
  end

  should 'convert hundreds' do
    in_words = NumberInWords.new(100)
    assert_equal "one hundred", in_words.convert
    in_words.number = 203
    assert_equal "two hundred three", in_words.convert
    in_words.number = 666
    assert_equal "six hundred sixty six", in_words.convert
    in_words.number = 791
    assert_equal "seven hundred ninety one", in_words.convert
    in_words.number = 903
    assert_equal "nine hundred three", in_words.convert
  end

  should 'convert thousands' do
    in_words = NumberInWords.new(1012)
    assert_equal "one thousand twelve", in_words.convert
    in_words.number = 2403
    assert_equal "two thousand four hundred three", in_words.convert
    in_words.number = 100007
    assert_equal "one hundred thousand seven", in_words.convert
    in_words.number = 791051
    assert_equal "seven hundred ninety one thousand fifty one", in_words.convert
  end

end