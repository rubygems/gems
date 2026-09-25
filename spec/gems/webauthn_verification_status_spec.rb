# frozen_string_literal: true

RSpec.describe Gems::WebAuthnVerificationStatus do
  subject(:status) { described_class.new("status" => "success", "code" => "123456") }

  it "is a Resource" do
    expect(status).to be_a(Gems::Resource)
  end

  it "inspects as the status, without the one-time passcode" do
    expect(status.inspect).to eq('#<Gems::WebAuthnVerificationStatus status="success">')
  end

  it "exposes the status" do
    expect(status.status).to eq("success")
  end

  it "exposes the one-time passcode" do
    expect(status.code).to eq("123456")
  end

  it "exposes why the verification is not done" do
    expect(described_class.new("status" => "expired", "message" => "The token has expired").message).to eq("The token has expired")
  end

  it "matches a pattern by its status" do
    matched = case status
    in {status: "success", code: String => code} then code
    end

    expect(matched).to eq("123456")
  end
end
