require File.dirname(__FILE__) + '/../test_helper'

class CardGeneratorTest < ActiveSupport::TestCase
  context "Generator instance" do
    setup do
      DomainChecks.disable do
        @plan = Factory.create(:free_plan, :items_limit => nil)
        @domain = Factory.create(:domain, :plan => @plan)
        @project = Factory.create(:project, :domain => @domain)
        Domain.current = @domain
        Project.current = @project
        @items = []
        1.upto(8) do |i|
          @items << Factory.create(:item_fake, :project => @project)
        end
      end
    end

    should "setup default options" do
      @generator = CardGenerator.new(@items)
      assert_equal('a4', @generator.options[:paper])
      assert_equal('portrait', @generator.options[:orientation])
      assert_equal(2, @generator.column_count)
      assert_equal(3, @generator.row_count)
      assert_equal(8, @generator.elements.size)
      assert_equal(@items, @generator.elements)
    end

    should "allow setting paper size" do
      @generator = CardGenerator.new(@items, {:paper => 'letter'})
      assert_equal('letter', @generator.options[:paper])
    end

    should "allow setting orientation" do
      @generator = CardGenerator.new(@items, {:orientation => 'landscape'})
      assert_equal('landscape', @generator.options[:orientation])
    end

    should "generate pdf content" do
      assert_nothing_raised do
        @generator = CardGenerator.new(@items)
        @content = @generator.generate_output
      end
      assert_not_nil(@content)
    end
  end
end
