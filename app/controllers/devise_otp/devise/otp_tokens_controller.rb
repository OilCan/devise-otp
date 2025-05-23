module DeviseOtp
  module Devise
    class OtpTokensController < DeviseController
      include ::Devise::Controllers::Helpers

      prepend_before_action :ensure_credentials_refresh
      prepend_before_action :authenticate_scope!

      protect_from_forgery except: [:clear_persistence, :delete_persistence]

      #
      # Displays the status of OTP authentication
      #
      def show
        if resource.nil?
          redirect_to stored_location_for(scope) || :root
        else
          render :show
        end
      end

      #
      # Displays the QR Code and Validation Token form for enabling the OTP
      #
      def edit
        resource.populate_otp_secrets!
      end

      #
      # Updates the status of OTP authentication
      #
      def update
        if resource.valid_otp_token?(params[:confirmation_code])
          resource.enable_otp!
          otp_set_flash_message :success, :successfully_updated
          redirect_to otp_token_path_for(resource)
        else
          otp_set_flash_message :alert, :could_not_confirm, :now => true
          render :edit
        end
      end

      #
      # Resets OTP authentication, generates new credentials, sets it to off
      #
      def destroy
        if resource.disable_otp!
          otp_set_flash_message :success, :successfully_disabled_otp
        end

        redirect_to otp_token_path_for(resource)
      end

      #
      # makes the current browser persistent
      #
      def get_persistence
        if otp_set_trusted_device_for(resource)
          otp_set_flash_message :success, :successfully_set_persistence
        end

        redirect_to otp_token_path_for(resource)
      end

      #
      # clears persistence for the current browser
      #
      def clear_persistence
        if otp_clear_trusted_device_for(resource)
          otp_set_flash_message :success, :successfully_cleared_persistence
        end

        redirect_to otp_token_path_for(resource)
      end

      #
      # rehash the persistence secret, thus, making all the persistence cookies invalid
      #
      def delete_persistence
        if otp_reset_persistence_for(resource)
          otp_set_flash_message :notice, :successfully_reset_persistence
        end

        redirect_to otp_token_path_for(resource)
      end

      def recovery
        respond_to do |format|
          format.html
          format.js
          format.text do
            send_data render_to_string(template: "#{controller_path}/recovery_codes"), filename: "otp-recovery-codes.txt", format: "text"
          end
        end
      end

      def reset
        if resource.disable_otp!
          resource.clear_otp_fields!
          otp_set_flash_message :success, :successfully_reset_otp
        end

        redirect_to edit_otp_token_path_for(resource)
      end

      private

      def ensure_credentials_refresh
        ensure_resource!

        if needs_credentials_refresh?(resource)
          redirect_to refresh_otp_credential_path_for(resource)
        end
      end

      def scope
        resource_name.to_sym
      end

      def self.controller_path
        "#{::Devise.otp_controller_path}/otp_tokens"
      end
    end
  end
end
