require "parallel"

class WordComplexityJob < ApplicationJob
  queue_as :default

  def perform(job_id)
    return unless Job.where(id: job_id, status: "pending")
                     .update_all(status: "in_progress") == 1

    job = Job.find(job_id)

    results = Parallel.map(job.words, in_threads: 10) do |word|
      result = WordComplexityService.call(word)
      [word, result.success? ? result.value : nil]
    end.to_h

    status = results.values.all?(&:nil?) ? "failed" : "completed"
    job.update!(status: status, result: results)
  rescue ActiveRecord::RecordNotFound
    # job was deleted, nothing to do
  rescue => e
    job&.update!(status: "failed", result: { error: e.message })
    raise
  end
end
