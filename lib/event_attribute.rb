# Copyright (c) 2007 Jonathan Younger
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'active_record'

module Daikini
  # EventAttribute allows you to turn your date/datetime columns in to boolean attributes.
  # Idea for this was taken from http://jamis.jamisbuck.org/articles/2005/12/14/two-tips-for-working-with-databases-in-rails
  #
  #   class Referral < ActiveRecord::Base
  #     event_attribute :applied_at, :attribute => 'pending', :nil_equals => true
  #     event_attribute :subscribed_on
  #   end
  #
  # Example:
  #
  #   referral = Referral.create(:applied_at => Time.now, :subscribed_on => nil)
  #   referral.pending?           # => false
  #   referral.subscribed?        # => false
  # 
  #   referral.pending = true
  #   referral.applied_at         # => nil
  #   referral.pending?           # => true
  # 
  #   referral.subscribed = true
  #   referral.subscribed_at      # => Time.now
  #   referral.subscribed?        # => true
  #
  #   # Dynamic finders are also added so that you can search on these boolean attributes.
  #   Referral.find_all_by_pending(true)  # => [Referral objects]
  # 
  #   # or
  #   Referral.find_by_name_and_pending_and_subscribed('John Smith', false, true)  # => Referral object
  #
  # See Daikini::EventAttribute::ClassMethods#event_attribute for configuration options
  module EventAttribute #:nodoc:

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # == Configuration options
      #
      # * <tt>attribute</tt> - name of the attribute that will be created in the model that returns true/false (default: column name minus '_at' or '_on')
      # * <tt>nil_equals</tt> - whether or not the attribute should return true or false if the column is nil (default: false)
      #
      def event_attribute(column, options = {})
        unless respond_to? :event_attribute_attrs
          class_eval { cattr_accessor :event_attributes, :event_attribute_attrs } 
          self.event_attributes, self.event_attribute_attrs = {}, {}
        end
        
        attribute = (options[:attribute] || (column.to_s =~ /_at|_on/ ? column.to_s[0...-3] : raise("Unable to create default attribute name"))).to_sym
        
        nil_equals = options[:nil_equals] || false
        
        self.event_attribute_attrs[attribute] = column
        self.event_attributes[column] = nil_equals
        
        create_attribute_accessors(attribute, column, nil_equals)

        class_eval { extend Daikini::EventAttribute::SingletonMethods }
      end
      
      private
      def create_attribute_accessors(attribute, column, nil_equals)
        define_method(attribute) { (nil_equals ? self[column].nil? : !self[column].nil?) }
        alias_method :"#{attribute.to_s}?", attribute
        
        # define the method to set the field value
        define_method(:"#{attribute.to_s}=") do |value|
          if [true, "1", 1, "t", "true"].include? value
            send("#{column}=", nil_equals ? nil : Time.now)
          elsif [false, "0", 0, "f", "false"].include? value
            send("#{column}=", nil_equals ? Time.now : nil)
          end
        end
      end
    end
    
    module SingletonMethods
      private
        #we need our own all_attributes_exists in order to hack the dynamic Active Record finders
        def all_attributes_exists?(attribute_names)
          attrs = column_methods_hash.merge(self.event_attribute_attrs)
          attribute_names.all? { |name| attrs.include?(name.to_sym) }
        end
      
        # Needed by Edge 
        
        # also requires a new construct_attributes_from_arguments
        def construct_attributes_from_arguments(attribute_names, arguments)
          attributes = {}
          attribute_names.each_with_index do |name, idx|
            if self.event_attribute_attrs.include? name.to_sym
              nil_equals = self.event_attributes[self.event_attribute_attrs[name.to_sym]]
              attributes[self.event_attribute_attrs[name.to_sym]] = case arguments[idx]
              when true, "1", 1, "t"
                nil_equals ? "IS NULL" : "IS NOT NULL"
              else
                nil_equals ? "IS NOT NULL" : "IS NULL"
              end
            else
              attributes[name] = arguments[idx]
            end
          end
          attributes
        end
      
        def attribute_condition(argument)
          case argument
            when nil   then "IS ?"
            when Array then "IN (?)"
            when "IS NOT NULL", "IS NULL" then "?"
            else            "= ?"
          end
        end
        
        def quote_bound_value(value) #:nodoc:
          if value.respond_to?(:map) && !value.is_a?(String)
            if value.respond_to?(:empty?) && value.empty?
              connection.quote(nil)
            else
              value.map { |v| connection.quote(v) }.join(',')
            end
          elsif ["IS NOT NULL", "IS NULL"].include?(value)
            value
          else
            connection.quote(value)
          end
        end
        
        
        # Needed For 1.2
        
        # also requires a new construct_conditions_from_arguments
        def construct_conditions_from_arguments(attribute_names, arguments)
          conditions = []
          if attribute_names.find { |a| self.event_attribute_attrs[a.to_sym] }
            attribute_names, arguments, event_attribute_conditions = construct_event_attribute_conditions(attribute_names, arguments)
            conditions << event_attribute_conditions
          end
          attribute_names.each_with_index { |name, idx| conditions << "#{table_name}.#{name} #{attribute_condition(arguments[idx])} " }
          [ conditions.join(" AND "), *arguments[0...attribute_names.length] ]
        end

        # checks the given list if attribute names for any event flag attributes and constructs
        # the proper sql.
        def construct_event_attribute_conditions(attribute_names, arguments)
          attr_names, args = attribute_names.dup, arguments.dup # so we don"t delete the originals
          event_attribute_values_and_columns, attrs_to_delete = [], []    
          attr_names.each_with_index do |name, idx|
            if field_value = self.event_attribute_attrs[name.to_sym]
              attrs_to_delete << idx
              event_attribute_values_and_columns << [field_value, args[idx]]
            end
          end
          attrs_to_delete.sort.reverse.each { |i| attr_names.delete_at(i); args.delete_at(i) }

          return attr_names, args, event_attribute_condition_sql(event_attribute_values_and_columns)
        end

        # builds the sql fragment for event flag searches
        def event_attribute_condition_sql(values)
          sql_pieces = values.collect do |v|
            if [true, "1", 1, "t"].include? v.last
              where = self.event_attributes[v.first.to_sym] ? "IS NULL" : "IS NOT NULL"
            elsif [false, "0", 0, "f"].include? v.last
              where = self.event_attributes[v.first.to_sym] ? "IS NOT NULL" : "IS NULL"
            end
            "(#{table_name}.#{v.first} #{where})"
          end
          sql_pieces.join(" AND ")
        end
    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it
ActiveRecord::Base.send :include, Daikini::EventAttribute
