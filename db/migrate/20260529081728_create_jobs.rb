class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs do |t|
      t.string :job_id
      t.string :status
      t.jsonb :words
      t.jsonb :result

      t.timestamps
    end
  end
end
