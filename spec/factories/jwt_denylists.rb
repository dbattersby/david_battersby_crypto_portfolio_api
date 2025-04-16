FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-04-12 11:13:17" }
  end
end
