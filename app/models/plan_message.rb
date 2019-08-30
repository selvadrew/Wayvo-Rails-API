class PlanMessage < ApplicationRecord
  belongs_to :plan
  belongs_to :user

  after_create_commit { PlanMessageBroadcastJob.perform_later self }
  
end
