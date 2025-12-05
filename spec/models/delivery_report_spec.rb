require 'rails_helper'

RSpec.describe DeliveryReport, type: :model do
  let(:delivery_company) { create(:delivery_company) }
  let(:delivery_user) { create(:delivery_user, delivery_company: delivery_company) }
  let(:order) { create(:order, delivery_company: delivery_company) }
  let(:delivery_assignment) { create(:delivery_assignment, order: order, delivery_user: delivery_user, delivery_company: delivery_company) }

  describe 'associations' do
    it 'belongs to delivery_assignment' do
      report = build(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user)
      expect(report.delivery_assignment).to eq(delivery_assignment)
    end

    it 'belongs to delivery_user' do
      report = build(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user)
      expect(report.delivery_user).to eq(delivery_user)
    end
  end

  describe 'validations' do
    subject { build(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user) }

    it 'validates presence of delivery_assignment_id' do
      report = build(:delivery_report, delivery_assignment: nil, delivery_user: delivery_user)
      expect(report).not_to be_valid
      expect(report.errors[:delivery_assignment]).to be_present
    end

    it 'validates presence of delivery_user_id' do
      report = build(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: nil)
      expect(report).not_to be_valid
      expect(report.errors[:delivery_user]).to be_present
    end

    it 'validates uniqueness of delivery_assignment_id' do
      create(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user)
      duplicate = build(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:delivery_assignment_id]).to be_present
    end

    it 'validates report_type inclusion' do
      report = build(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user, report_type: 'invalid')
      expect(report).not_to be_valid
      expect(report.errors[:report_type]).to be_present
    end

    it 'validates latitude range' do
      report = build(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user, latitude: 100)
      expect(report).not_to be_valid

      report.latitude = -100
      expect(report).not_to be_valid

      report.latitude = 35.6812
      expect(report).to be_valid
    end

    it 'validates longitude range' do
      report = build(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user, longitude: 200)
      expect(report).not_to be_valid

      report.longitude = -200
      expect(report).not_to be_valid

      report.longitude = 139.7671
      expect(report).to be_valid
    end

    context 'with issue or failed report_type' do
      it 'requires issue_type' do
        report = build(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user, report_type: 'issue', issue_type: nil)
        expect(report).not_to be_valid

        report.issue_type = 'absent'
        expect(report).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:completed_report) { create(:delivery_report) }
    let!(:failed_report) { create(:delivery_report, :failed) }
    let!(:issue_report) { create(:delivery_report, :issue) }

    it 'returns completed reports' do
      expect(DeliveryReport.completed).to include(completed_report)
      expect(DeliveryReport.completed).not_to include(failed_report, issue_report)
    end

    it 'returns failed reports' do
      expect(DeliveryReport.failed).to include(failed_report)
      expect(DeliveryReport.failed).not_to include(completed_report, issue_report)
    end

    it 'returns issue reports' do
      expect(DeliveryReport.issues).to include(issue_report)
      expect(DeliveryReport.issues).not_to include(completed_report, failed_report)
    end
  end

  describe 'methods' do
    it '#completed? returns true for completed report' do
      report = build(:delivery_report, report_type: 'completed')
      expect(report.completed?).to be true
    end

    it '#failed? returns true for failed report' do
      report = build(:delivery_report, report_type: 'failed')
      expect(report.failed?).to be true
    end

    it '#has_issue? returns true for issue report' do
      report = build(:delivery_report, report_type: 'issue')
      expect(report.has_issue?).to be true
    end

    it '#has_location? returns true when lat/lng present' do
      report = build(:delivery_report, latitude: 35.6812, longitude: 139.7671)
      expect(report.has_location?).to be true

      report.latitude = nil
      expect(report.has_location?).to be false
    end

    it '#delivery_duration calculates duration in minutes' do
      report = build(:delivery_report,
                     started_at: Time.zone.parse('2025-01-01 10:00:00'),
                     completed_at: Time.zone.parse('2025-01-01 10:30:00'))
      expect(report.delivery_duration).to eq(30)
    end
  end
end
