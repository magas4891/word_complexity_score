class ComplexityScoresController < ApplicationController
  def create
    words = params[:words]

    return render json: { error: "words must be a non-empty array" }, status: :unprocessable_content unless valid_words?(words)

    job = Job.create!(
      job_id: SecureRandom.uuid,
      status: "pending",
      words: words,
      result: {}
    )

    WordComplexityJob.perform_later(job.id)

    render json: { job_id: job.job_id }, status: :accepted
  end

  def show
    job = Job.find_by(job_id: params[:job_id])

    return render json: { error: "Job not found" }, status: :not_found unless job

    response = { status: job.status }
    response[:result] = job.result if job.status == "completed"

    render json: response
  end

  private

  def valid_words?(words)
    words.is_a?(Array) && words.any? && words.all? { |w| w.is_a?(String) && w.present? }
  end
end
