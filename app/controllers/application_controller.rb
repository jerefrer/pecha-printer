class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  private

  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
  end

  def extract_locale
    param = params[:locale]
    if param && I18n.available_locales.map(&:to_s).include?(param)
      cookies.permanent[:locale] = param
      return param
    end
    saved = cookies[:locale]
    saved if saved && I18n.available_locales.map(&:to_s).include?(saved)
  end
end
