class Api::DashboardController < ApplicationController
  before_action :authenticate_user!

  DIFFICULTY_LABELS = { 7 => "Fácil", 3 => "Médio", 1 => "Difícil", nil => "Não estudado" }.freeze
  DIFFICULTY_ORDER = [ 7, 3, 1, nil ].freeze

  def index
    deck_id = params[:deck_id].presence
    if deck_id
      deck = current_user.decks.find_by(id: deck_id)
      return render json: { error: "Deck não encontrado" }, status: :not_found unless deck
    end

    cards_scope = Card.where(deck_id: current_user.decks.select(:id))
    cards_scope = cards_scope.where(deck_id: deck_id) if deck_id

    difficulty_card_counts = cards_scope.group(:last_difficulty).count
    cards_by_difficulty = DIFFICULTY_ORDER.map do |value|
      { difficulty: value, label: DIFFICULTY_LABELS[value], count: difficulty_card_counts[value] || 0 }
    end

    totals = {
      total_cards: cards_scope.count,
      reviewed_cards: cards_scope.where.not(last_difficulty: nil).count
    }

    base_query = CardReview.joins(card: :deck).where(decks: { user_id: current_user.id })
    base_query = base_query.where(cards: { deck_id: deck_id }) if deck_id

    review_dates = base_query.select("DISTINCT DATE(card_reviews.date)").order("DATE(card_reviews.date) DESC").pluck("DATE(card_reviews.date)").map(&:to_date)
    streaks = calculate_streaks(review_dates)

    period = params[:period] || "7_days"
    filtered_query = case period
    when "7_days"
      base_query.where("card_reviews.date >= ?", 7.days.ago)
    when "30_days"
      base_query.where("card_reviews.date >= ?", 30.days.ago)
    when "3_months"
      base_query.where("card_reviews.date >= ?", 3.months.ago)
    else
      base_query
    end

    difficulty_counts = filtered_query.group(:difficulty).order("count_all DESC").count
    difficulties = difficulty_counts.map { |difficulty, count| { difficulty: difficulty, count: count } }

    date_grouped_counts = filtered_query.group("DATE(card_reviews.date)").count
    start_date = case params[:period]
    when "7_days"   then 7.days.ago.to_date
    when "30_days"  then 30.days.ago.to_date
    when "3_months" then 3.months.ago.to_date
    else
      review_dates.last || Date.today
    end
    end_date = Date.today

    date_range = (start_date..end_date)
    complete_counts = date_range.each_with_object({}) do |date, hash|
      hash[date] = 0
    end
    complete_counts.merge!(date_grouped_counts.transform_keys(&:to_date))

    reviews_over_time = complete_counts.map do |date, count|
      { date: date.iso8601, count: count }
    end

    render json: {
      cards_by_difficulty: cards_by_difficulty,
      totals: totals,
      difficulties: difficulties,
      reviews_over_time: reviews_over_time,
      streaks: streaks
    }
  end

  private

  def calculate_streaks(dates)
    return { current: 0, longest: 0 } if dates.empty?

    longest_streak = 0
    current_streak = 0

    if dates.first == Date.today || dates.first == Date.yesterday
      current_streak = 1
      (1...dates.length).each do |i|
        if dates[i] == dates[i - 1] - 1.day
          current_streak += 1
        else
          break
        end
      end
    end

    if dates.any?
      longest_streak = 1
      temp_streak = 1
      (1...dates.length).each do |i|
        if dates[i] == dates[i - 1] - 1.day
          temp_streak += 1
        else
          temp_streak = 1
        end
        longest_streak = [ longest_streak, temp_streak ].max
      end
    end

    { current: current_streak, longest: longest_streak }
  end
end
