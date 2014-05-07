module SpreeI18n
  # The fact this logic is in a single module also helps to apply a custom
  # locale on the spree/api context since api base controller inherits from
  # MetalController instead of Spree::BaseController
  module ControllerLocaleHelper
    extend ActiveSupport::Concern
    included do
      before_filter :set_user_language
      before_filter :globalize_fallbacks

      private
        # Overrides the Spree::Core::ControllerHelpers::Common logic so that only
        # supported locales defined by SpreeI18n::Config.supported_locales can
        # actually be set
        def set_user_language
          locale = params[:locale] if params[:locale].present? && Config.supported_locales.include?(params[:locale].to_sym)
          locale ||= Rails.application.config.i18n.default_locale || I18n.default_locale

          I18n.locale = locale

          if Spree::Config[:allow_currency_change]
            localized_currency = LOCALES_CURRENCIES_ASSOCIATIONS[I18n.locale] if defined?(LOCALES_CURRENCIES_ASSOCIATIONS)

            if localized_currency.present?
              currency = supported_currencies.find { |currency| currency.iso_code.eql?(localized_currency) }

              # make sure that we update the current order, so the currency change is reflected
              if defined?(current_order) && current_order.present?
                current_order.update_attributes!(currency: currency.iso_code)
              end

              session[:currency] = localized_currency
            end
          end
        end

        def globalize_fallbacks
          Fallbacks.config!
        end
    end
  end
end
