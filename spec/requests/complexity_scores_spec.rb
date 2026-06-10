require "rails_helper"

RSpec.describe "ComplexityScores", type: :request do
  describe "POST /complexity-score" do
    let(:words) { [ "happy", "sad" ] }
    let(:headers) { { "Content-Type" => "application/json" } }

    before { ActiveJob::Base.queue_adapter = :test }

    context "with a valid word array" do
      it "returns 202 with a job_id" do
        post "/complexity-score", params: { words: words }.to_json, headers: headers
        expect(response).to have_http_status(:accepted)
        expect(JSON.parse(response.body)).to have_key("job_id")
      end

      it "creates a Job record with pending status" do
        expect {
          post "/complexity-score", params: { words: words }.to_json, headers: headers
        }.to change(Job, :count).by(1)

        expect(Job.last.status).to eq("pending")
        expect(Job.last.words).to eq(words)
      end

      it "enqueues WordComplexityJob" do
        expect {
          post "/complexity-score", params: { words: words }.to_json, headers: headers
        }.to have_enqueued_job(WordComplexityJob)
      end
    end

    context "when job_id is not unique" do
      it "returns 422 with an error message" do
        allow(SecureRandom).to receive(:uuid).and_return("duplicate-id")
        create(:job, job_id: "duplicate-id")

        post "/complexity-score", params: { words: words }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)["error"]).to be_present
      end
    end

    context "with an empty array" do
      it "returns 422" do
        post "/complexity-score", params: { words: [] }.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)["error"]).to be_present
      end
    end

    context "with a non-array value" do
      it "returns 422" do
        post "/complexity-score", params: { words: "happy" }.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "without words param" do
      it "returns 422" do
        post "/complexity-score", params: {}.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /complexity-score/:job_id" do
    context "when the job is pending" do
      let(:job) { create(:job, status: "pending") }

      it "returns status pending" do
        get "/complexity-score/#{job.job_id}"
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["status"]).to eq("pending")
      end

      it "does not include result" do
        get "/complexity-score/#{job.job_id}"
        expect(JSON.parse(response.body)).not_to have_key("result")
      end
    end

    context "when the job is completed" do
      let(:job) { create(:job, status: "completed", result: { "happy" => 3.0, "sad" => 1.8 }) }

      it "returns status and result" do
        get "/complexity-score/#{job.job_id}"
        body = JSON.parse(response.body)
        expect(body["status"]).to eq("completed")
        expect(body["result"]).to eq({ "happy" => 3.0, "sad" => 1.8 })
      end
    end

    context "when the job does not exist" do
      it "returns 404" do
        get "/complexity-score/nonexistent-id"
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("Job not found")
      end
    end
  end
end
