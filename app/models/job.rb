class Job < ApplicationRecord
  validates :job_id, presence: true, uniqueness: true
end
