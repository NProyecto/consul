class RedeemableCode < ActiveRecord::Base
  VALID_CHARS = %W(A B C D E F H J K L M N P Q R S T U V W X Y Z 2 3 4 5 7 8 9)

  validates :token, uniqueness: true

  def self.generate_token
    (1..10).inject([]){|chars, _| chars << VALID_CHARS.sample} * ''
  end

  def self.redeemable?(token)
    self.where(token: token).exists?
  end

  def self.redeem(token, user)
    instance = self.where(token: token).first

    if instance.present?
      instance.delete
      user.update(redeemable_code: token, verified_at: DateTime.now)
      true
    else
      false
    end
  end

end
