class AddUniqueIndexToJobsJobId < ActiveRecord::Migration[8.1]
  def change
    add_index :jobs, :job_id, unique: true
  end
end
