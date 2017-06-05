module Salesforce
  ExportFailed = Class.new(StandardError)

  class ExportUserSkillRatingsService
    def all_rated
      UserSkillRate.where('rate > 0 OR favorite = true').find_each { |rating| sync(rating) }
    end

    def one(skill_rating_id)
      rating = UserSkillRate.find(skill_rating_id)
      sync(rating)
    end

    private

    def sync(rating)
      repository.delete(rating) && return unless rating.rate.positive? || rating.favorite
      repository.sync(rating)
      Rails.logger.info("UserSkillRating(id=#{ rating.id }) exported to Salesforce")
    end

    def repository
      @repository ||= Salesforce::UserSkillRatingsRepository.new(Restforce.new)
    end
  end
end
