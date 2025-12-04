require "rails_helper"

RSpec.describe InvoiceMailer, type: :mailer do
  describe "overdue_notice" do
    let(:mail) { InvoiceMailer.overdue_notice }

    it "renders the headers" do
      expect(mail.subject).to eq("Overdue notice")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "payment_reminder" do
    let(:mail) { InvoiceMailer.payment_reminder }

    it "renders the headers" do
      expect(mail.subject).to eq("Payment reminder")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
