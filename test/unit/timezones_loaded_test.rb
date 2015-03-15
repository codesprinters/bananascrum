require File.dirname(__FILE__) + '/../test_helper'

class TimezonesLoadedTest < ActiveSupport::TestCase

  def test_converting_works
    connection = Domain.connection
    result = connection.execute("SELECT CONVERT_TZ('2004-01-01 12:00:00','GMT','MET')")
    assert_not_nil result.first.values.first, "It seems your table with timezone information has not been populated.\nRun something like:\nmysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql\nto fix this!"
  end
  
end