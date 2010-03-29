class Conversation < ActiveRecord::Base
  serialize :statuses, Array
end
