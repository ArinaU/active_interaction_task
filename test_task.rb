# frozen_string_literal: true

class User < ApplicationRecord
  GENDERS = %w[male female].freeze
  has_many :interests_users, dependent: :destroy
  has_many :interests, through: :interests_users

  has_many :skills_users, dependent: :destroy
  has_many :skills, through: :skills_users

  validates :name, :patronymic, :email, :age, :nationality, :country, :gender, presence: true
  validates :age, numericality: { greater_than_or_equal_to: 0, less_than: 90 }
  validates :gender, inclusion: { in: GENDERS }

  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: true

  set_callback :validate, :before, -> { self.email = email.downcase }
end

class Interest < ApplicationRecord
  has_many :interest_users, dependent: :destroy
  has_many :users, through: :interests_users

  validates :name, presence: true, uniqueness: true
end

class InterestsUser < ApplicationRecord
  belongs_to :interest
  belongs_to :user

  validates :user_id, uniqueness: { scope: :interest_id }
end

class Skill < ApplicationRecord
  has_many :skills_users, dependent: :destroy
  has_many :users, through: :skills_users

  validates :name, presence: true, uniqueness: true
end

class SkillsUser < ApplicationRecord
  belongs_to :skill
  belongs_to :user

  validates :user_id, uniqueness: { scope: :skill_id }
end

module Users
  class Create < ActiveInteraction::Base
    string :name, :surname, :patronymic, :email, :nationality, :country, :gender
    integer :age
    string :fullname, default: nil
    array :interests, :skills, default: nil

    def execute
      user = User.new(
        name: name,
        surname: surname,
        patronymic: patronymic,
        email: email,
        nationality: nationality,
        country: country,
        gender: gender,
        age: age,
        fullname: fullname || [surname, name, patronymic].compact.join(' ')
      )

      initialize_interests(user)
      initialize_skills(user)

      errors.merge!(user.errors) unless user.save

      user
    end

    private

    def initialize_interests(user)
      return if interests.empty?

      interests.each do |name|
        interest = Interest.find_or_initialize_by(name: name)
        user.interests << interest unless user.interests.include?(interest)
      end
    end

    def initialize_skills(user)
      return if skills.empty?

      skills.each do |name|
        skill = Skill.find_or_initialize_by(name: name)
        user.skills << skill unless user.skills.include?(skill)
      end
    end
  end
end

# # User object in database
# name string
# surname string
# patronymic string
# fullname string
# email string
# age integer
# nationality string
# country string
# gender string
#
# # Interest object in database
# name string
#
# # Skill object in database
# name string
#
# #
# InterestsUser - join table
# user_id
# interest_id
#
# SkillsUser - join table
# user_id
# skill_id
