require File.dirname(__FILE__) + '/../test_helper'

class NumberInWordsPlTest < ActiveSupport::TestCase

  should 'convert unity' do
    in_words = NumberInWordsPl.new(1)
    assert_equal "jeden", in_words.convert
    in_words.number = 3
    assert_equal "trzy", in_words.convert
    in_words.number = 5
    assert_equal "pięć", in_words.convert
    in_words.number = 7
    assert_equal "siedem", in_words.convert
    in_words.number = 9
    assert_equal "dziewięć", in_words.convert
    in_words.number = 12
    assert_equal "dwanaście", in_words.convert
    in_words.number = 15
    assert_equal "piętnaście", in_words.convert
  end

  should 'convert decimal' do
    in_words = NumberInWordsPl.new(21)
    assert_equal "dwadzieścia jeden", in_words.convert
    in_words.number = 34
    assert_equal "trzydzieści cztery", in_words.convert
    in_words.number = 52
    assert_equal "pięćdziesiąt dwa", in_words.convert
    in_words.number = 68
    assert_equal "sześćdziesiąt osiem", in_words.convert
  end

  should 'convert hundreds' do
    in_words = NumberInWordsPl.new(100)
    assert_equal "sto", in_words.convert
    in_words.number = 203
    assert_equal "dwieście trzy", in_words.convert
    in_words.number = 666
    assert_equal "sześćset sześćdziesiąt sześć", in_words.convert
    in_words.number = 791
    assert_equal "siedemset dziewięćdziesiąt jeden", in_words.convert
    in_words.number = 903
    assert_equal "dziewięćset trzy", in_words.convert
  end

  should 'convert thousands' do
    in_words = NumberInWordsPl.new(1012)
    assert_equal "tysiąc dwanaście", in_words.convert
    in_words.number = 2403
    assert_equal "dwa tysiące czterysta trzy", in_words.convert
    in_words.number = 100007
    assert_equal "sto tysięcy siedem", in_words.convert
    in_words.number = 791051
    assert_equal "siedemset dziewięćdziesiąt jeden tysięcy pięćdziesiąt jeden", in_words.convert
  end

  should 'convert milions' do
    in_words = NumberInWordsPl.new(1012121)
    assert_equal "milion dwanaście tysięcy sto dwadzieścia jeden", in_words.convert
    in_words.number = 13012121
    assert_equal "trzynaście milionów dwanaście tysięcy sto dwadzieścia jeden", in_words.convert
    in_words.number = 100012121
    assert_equal "sto milionów dwanaście tysięcy sto dwadzieścia jeden", in_words.convert
    in_words.number = 218012121
    assert_equal "dwieście osiemnaście milionów dwanaście tysięcy sto dwadzieścia jeden", in_words.convert
    in_words.number = 666012121
    assert_equal "sześćset sześćdziesiąt sześć milionów dwanaście tysięcy sto dwadzieścia jeden", in_words.convert
  end

end