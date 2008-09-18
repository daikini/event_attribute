require 'abstract_unit'

class Referral < ActiveRecord::Base
  event_attribute :applied_at, :attribute => 'pending', :nil_equals => true
  event_attribute :subscribed_on
end

class EventAttributeTest < Test::Unit::TestCase
  def setup
    Referral.delete_all
  end
  
  def test_should_have_boolean_attribute_when_attribute_option_specified
    referral = Referral.new
    assert referral.respond_to?(:pending)
    assert referral.respond_to?(:pending?)
    assert referral.respond_to?(:pending=)
  end
  
  def test_should_have_default_attribute_when_attribute_option_not_specified
    referral = Referral.new
    assert referral.respond_to?(:subscribed)
    assert referral.respond_to?(:subscribed?)
    assert referral.respond_to?(:subscribed=)
  end
  
  def test_should_return_true_when_nil_equals_true_and_column_is_nil
    referral = Referral.new(:applied_at => nil)
    assert_nil referral.applied_at
    assert referral.pending?
  end
  
  def test_should_return_nil_when_nil_equals_true_and_attribute_is_true
    referral = Referral.new(:pending => true)
    assert referral.pending?
    assert_nil referral.applied_at
  end
  
  def test_should_return_nil_when_nil_equals_true_and_attribute_equals_integer_1
    referral = Referral.new(:pending => 1)
    assert referral.pending?
    assert_nil referral.applied_at
  end
  
  def test_should_return_nil_when_nil_equals_true_and_attribute_equals_string_1
    referral = Referral.new(:pending => "1")
    assert referral.pending?
    assert_nil referral.applied_at
  end
  
  def test_should_return_nil_when_nil_equals_true_and_attribute_equals_t
    referral = Referral.new(:pending => "t")
    assert referral.pending?
    assert_nil referral.applied_at
  end
  
  def test_should_return_false_when_nil_equals_true_and_column_is_not_nil
    referral = Referral.new(:applied_at => Time.now)
    assert_not_nil referral.applied_at
    assert !referral.pending?
  end
  
  def test_should_return_time_when_nil_equals_true_and_attribute_is_false
    referral = Referral.new(:pending => false)
    assert !referral.pending?
    assert_kind_of Time, referral.applied_at
  end
  
  def test_should_return_time_when_nil_equals_true_and_attribute_equals_integer_0
    referral = Referral.new(:pending => 0)
    assert !referral.pending?
    assert_kind_of Time, referral.applied_at
  end
  
  def test_should_return_time_when_nil_equals_true_and_attribute_equals_string_0
    referral = Referral.new(:pending => "0")
    assert !referral.pending?
    assert_kind_of Time, referral.applied_at
  end
  
  def test_should_return_time_when_nil_equals_true_and_attribute_equals_f
    referral = Referral.new(:pending => "f")
    assert !referral.pending?
    assert_kind_of Time, referral.applied_at
  end
  
  def test_should_return_false_when_nil_equals_false_and_column_is_nil
    referral = Referral.new(:subscribed_on => nil)
    assert_nil referral.subscribed_on
    assert !referral.subscribed?
  end
  
  def test_should_return_time_when_nil_equals_false_and_attribute_is_true
    referral = Referral.new(:subscribed => true)
    assert referral.subscribed?
    assert_kind_of Time, referral.subscribed_on
  end
  
  def test_should_return_time_when_nil_equals_false_and_attribute_equals_integer_1
    referral = Referral.new(:subscribed => 1)
    assert referral.subscribed?
    assert_kind_of Time, referral.subscribed_on
  end
  
  def test_should_return_time_when_nil_equals_false_and_attribute_equals_string_1
    referral = Referral.new(:subscribed => "1")
    assert referral.subscribed?
    assert_kind_of Time, referral.subscribed_on
  end
  
  def test_should_return_time_when_nil_equals_false_and_attribute_equals_t
    referral = Referral.new(:subscribed => "t")
    assert referral.subscribed?
    assert_kind_of Time, referral.subscribed_on
  end
  
  def test_should_return_true_when_nil_equals_false_and_column_is_not_nil
    referral = Referral.new(:subscribed_on => Time.now)
    assert_not_nil referral.subscribed_on
    assert referral.subscribed?
  end
  
  def test_should_return_nil_when_nil_equals_false_and_attribute_is_false
    referral = Referral.new(:subscribed => false)
    assert !referral.subscribed?
    assert_nil referral.subscribed_on
  end
  
  def test_should_return_nil_when_nil_equals_false_and_attribute_equals_integer_0
    referral = Referral.new(:subscribed => 0)
    assert !referral.subscribed?
    assert_nil referral.subscribed_on
  end
  
  def test_should_return_nil_when_nil_equals_false_and_attribute_equals_string_0
    referral = Referral.new(:subscribed => "0")
    assert !referral.subscribed?
    assert_nil referral.subscribed_on
  end
  
  def test_should_return_nil_when_nil_equals_false_and_attribute_equals_f
    referral = Referral.new(:subscribed => "f")
    assert !referral.subscribed?
    assert_nil referral.subscribed_on
  end
  
  def test_should_find_referral_when_nil_equals_true_and_column_is_nil
    referral = Referral.create :applied_at => nil
    assert_equal referral, Referral.find_by_pending(true)
  end
  
  def test_should_find_referral_when_nil_equals_true_and_column_is_not_nil
    referral = Referral.create :applied_at => Time.now
    assert_equal referral, Referral.find_by_pending(false)
  end
  
  def test_should_find_referral_when_nil_equals_false_and_column_is_nil
    referral = Referral.create :subscribed_on => nil
    assert_equal referral, Referral.find_by_subscribed(false)
  end
  
  def test_should_find_referral_when_nil_equals_false_and_column_is_not_nil
    referral = Referral.create :subscribed_on => Time.now
    assert_equal referral, Referral.find_by_subscribed(true)
  end
  
  def test_should_find_referral_with_multiple_columns
    referral = Referral.create :name => "John Smith", :subscribed_on => Time.now, :applied_at => Time.now
    assert_equal referral, Referral.find_by_name_and_pending_and_subscribed("John Smith", false, true)
  end
  
  def test_should_not_find_a_referral
    referral = Referral.create :name => "John Smith", :subscribed_on => Time.now, :applied_at => Time.now
    assert_nil Referral.find_by_name_and_pending_and_subscribed("Bob Hope", false, true)
    assert_nil Referral.find_by_name_and_pending_and_subscribed("John Smith", true, true)
    assert_nil Referral.find_by_name_and_pending_and_subscribed("John Smith", false, false)
  end
end
