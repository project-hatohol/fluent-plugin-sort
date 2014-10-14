# Copyright (C) 2014 Project Hatohol
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

require "fluent/plugin/out_sort"

class SortTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  private
  def create_driver(configuration)
    driver = Fluent::Test::BufferedOutputTestDriver.new(Fluent::SortOutput, tag)
    driver.configure(configuration)
    driver
  end

  def tag
    "log.message"
  end

  sub_test_case "configuration" do
    sub_test_case "valid" do
      test "time" do
        driver = create_driver("sort_key time")
        assert_equal(:time, driver.instance.sort_key)
      end

      sub_test_case "attribute" do
        test "single" do
          driver = create_driver("sort_key attribute:timestamp")
          assert_equal(["timestamp"], driver.instance.sort_key)
        end

        test "nested" do
          driver = create_driver("sort_key attribute:body.timestamp")
          assert_equal(["body", "timestamp"], driver.instance.sort_key)
        end
      end
    end

    sub_test_case "invalid" do
      test "no <attribute:> prefix" do
        message = "sort_key must be <time> or <attribute:NAME>: <timestamp>"
        assert_raise(Fluent::ConfigError.new(message)) do
          create_driver("sort_key timestamp")
        end
      end
    end
  end

  sub_test_case "messaging" do
    sub_test_case "sort" do
      test "time" do
        driver = create_driver("sort_key time")
        base_time = Time.parse("2014-10-14T02:26:42Z").to_i
        driver.emit({"id" => "4"}, base_time + 1)
        driver.emit({"id" => "5"}, base_time + 2)
        driver.emit({"id" => "2"}, base_time - 1)
        driver.emit({"id" => "1"}, base_time - 2)
        driver.emit({"id" => "3"}, base_time)
        driver.run
        assert_equal([
                       [tag, base_time - 2, {"id" => "1"}],
                       [tag, base_time - 1, {"id" => "2"}],
                       [tag, base_time,     {"id" => "3"}],
                       [tag, base_time + 1, {"id" => "4"}],
                       [tag, base_time + 2, {"id" => "5"}],
                     ],
                     driver.emits)
      end

      sub_test_case "attribute" do
        test "single" do
          driver = create_driver("sort_key attribute:timestamp")
          base_timestamp = Time.parse("2014-10-14T02:26:42Z").to_i
          driver.emit({"timestamp" => base_timestamp + 1}, Fluent::Engine.now)
          driver.emit({"timestamp" => base_timestamp + 2}, Fluent::Engine.now)
          driver.emit({"timestamp" => base_timestamp - 1}, Fluent::Engine.now)
          driver.emit({"timestamp" => base_timestamp - 2}, Fluent::Engine.now)
          driver.emit({"timestamp" => base_timestamp},     Fluent::Engine.now)
          driver.run
          assert_equal([
                         {"timestamp" => base_timestamp - 2},
                         {"timestamp" => base_timestamp - 1},
                         {"timestamp" => base_timestamp},
                         {"timestamp" => base_timestamp + 1},
                         {"timestamp" => base_timestamp + 2},
                       ],
                       driver.records)
        end

        test "nested" do
          driver = create_driver("sort_key attribute:body.timestamp")
          base_timestamp = Time.parse("2014-10-14T02:26:42Z").to_i
          driver.emit({"body" => {"timestamp" => base_timestamp + 1}},
                      Fluent::Engine.now)
          driver.emit({"body" => {"timestamp" => base_timestamp + 2}},
                      Fluent::Engine.now)
          driver.emit({"body" => {"timestamp" => base_timestamp - 1}},
                      Fluent::Engine.now)
          driver.emit({"body" => {"timestamp" => base_timestamp - 2}},
                      Fluent::Engine.now)
          driver.emit({"body" => {"timestamp" => base_timestamp}},
                      Fluent::Engine.now)
          driver.run
          assert_equal([
                         {"body" => {"timestamp" => base_timestamp - 2}},
                         {"body" => {"timestamp" => base_timestamp - 1}},
                         {"body" => {"timestamp" => base_timestamp}},
                         {"body" => {"timestamp" => base_timestamp + 1}},
                         {"body" => {"timestamp" => base_timestamp + 2}},
                       ],
                       driver.records)
        end

        test "nonexistent" do
          driver = create_driver("sort_key attribute:timestamp")
          base_timestamp = Time.parse("2014-10-14T02:26:42Z").to_i
          driver.emit({"timestamp" => base_timestamp + 1}, Fluent::Engine.now)
          driver.emit({"timestamp" => base_timestamp + 2}, Fluent::Engine.now)
          driver.emit({"time"      => base_timestamp - 1}, Fluent::Engine.now)
          driver.emit({"timestamp" => base_timestamp - 2}, Fluent::Engine.now)
          driver.emit({"timestamp" => base_timestamp},     Fluent::Engine.now)
          driver.run
          assert_equal([
                         {"time"      => base_timestamp - 1},
                         {"timestamp" => base_timestamp - 2},
                         {"timestamp" => base_timestamp},
                         {"timestamp" => base_timestamp + 1},
                         {"timestamp" => base_timestamp + 2},
                       ],
                       driver.records)
        end
      end
    end

    sub_test_case "tag" do
      test "add_tag_prefix" do
        tag_prefix = "sorted."
        driver = create_driver(<<-CONFIGURE)
          sort_key time
          add_tag_prefix #{tag_prefix}
        CONFIGURE
        base_time = Time.parse("2014-10-14T02:26:42Z").to_i
        driver.emit({"id" => "1"}, base_time)
        driver.run
        assert_equal([
                       ["#{tag_prefix}#{tag}", base_time, {"id" => "1"}],
                     ],
                     driver.emits)
      end
    end
  end
end
