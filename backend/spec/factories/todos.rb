FactoryBot.define do
  factory :todo do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    completed { false }
    association :user
  end
end
