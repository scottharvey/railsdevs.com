class Conversation < ApplicationRecord
  belongs_to :developer
  belongs_to :business

  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  has_noticed_notifications

  validates :developer_id, uniqueness: {scope: :business_id}

  scope :blocked, -> { where.not(developer_blocked_at: nil).or(Conversation.where.not(business_blocked_at: nil)) }
  scope :visible, -> { where(developer_blocked_at: nil, business_blocked_at: nil) }

  after_create_commit :send_admin_notification

  def other_recipient(user)
    developer == user.developer ? business : developer
  end

  def business?(user)
    business == user.business
  end

  def developer?(user)
    developer == user.developer
  end

  def blocked?
    developer_blocked_at.present? || business_blocked_at.present?
  end

  def hiring_fee_eligible?
    developer_replied? && created_at <= 2.weeks.ago
  end

  private

  def send_admin_notification
    NewConversationNotification.with(conversation: self).deliver_later(User.admin)
  end

  def developer_replied?
    messages.from_developer.any?
  end
end
