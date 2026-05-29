FactoryBot.define do
  factory :job do
    job_id { SecureRandom.uuid }
    status { "pending" }
    words { [ "happy", "sad" ] }
    result { {} }
  end
end
