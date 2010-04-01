class User < ActiveRecord::Base
  has_many :statuses
  serialize :subscriptions, Array
end
