ActiveRecord::Schema.define(:version => 1) do
  create_table "referrals", :force => true do |t|
    t.column :name, :string
    t.column :applied_at, :datetime
    t.column :subscribed_on, :date
  end
end