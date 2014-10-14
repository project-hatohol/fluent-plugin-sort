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

require "English"

module Fluent
  class SortOutput < BufferedOutput
    Plugin.register_output("sort", self)

    include HandleTagNameMixin

    config_param :sort_key, :default => :time do |value|
      case value
      when "time"
        :time
      when /\Aattribute:/
        $POSTMATCH.split(".")
      else
        message = "sort_key must be <time> or <attribute:NAME>: <#{value}>"
        raise ConfigError, message
      end
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      messages = sort_messages(chunk.to_enum(:msgpack_each))
      messages.each do |tag, time, record|
        Engine.emit(tag, time, record)
      end
    end

    private
    def sort_messages(messages)
      case @sort_key
      when :time
        sort_by_time(messages)
      when Array
        sort_by_attribute(messages)
      end
    end

    def sort_by_time(messages)
      messages.sort_by do |tag, time, record|
        time
      end
    end

    def sort_by_attribute(messages)
      value_cache = {}
      messages.sort do |message1, message2|
        if value_cache.key?(message1)
          value1 = value_cache[message1]
        else
          value1 = value_cache[message1] = extract_sort_value(message1)
        end
        if value_cache.key?(message2)
          value2 = value_cache[message2]
        else
          value2 = value_cache[message2] = extract_sort_value(message2)
        end

        if value1 == value2
          0
        elsif value1.nil? or value2.nil?
          if value1.nil?
            -1
          else
            1
          end
        else
          value1 <=> value2
        end
      end
    end

    def extract_sort_value(message)
      _, _, record = message
      @sort_key.reduce(record) do |current_item, key|
        case current_item
        when Hash
          current_item[key]
        else
          nil
        end
      end
    end
  end
end
