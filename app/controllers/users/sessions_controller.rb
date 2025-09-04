# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include ProcedureContextConcern
  include TrustedDeviceConcern
  include ActionView::Helpers::DateHelper
  include FranceConnectConcern
  include ProConnectSessionConcern

  layout 'login', only: [:new, :create]

  before_action :redirect_to_pro_connect_if_mandatory, only: [:create]
  before_action :restore_procedure_context, only: [:new, :create]
  skip_before_action :redirect_if_untrusted, only: [:reset_link_sent]
  # POST /resource/sign_in
  def create
    user = User.find_by(user_email_params)

    if user&.valid_password?(user_password_params[:password])
      delete_france_connect_cookies
      delete_pro_connect_session_info_cookie
      user.update(loged_in_with_france_connect: nil)
      user.update_preferred_domain(Current.host) if helpers.switch_domain_enabled?(request)
    end

    super
    if current_account.count > 1
      flash[:notice] = t("devise.sessions.signed_in_multiple_profile", roles: current_account.keys.map { |role| t("layouts.#{role}") }.to_sentence)
    end
  end

  def reset_link_sent
    if send_login_token_or_bufferize(current_instructeur)
      flash[:notice] = "Nous venons de vous renvoyer un nouveau lien de connexion sécurisée à #{Current.application_name}"
    end

    signed_email = message_encryptor_service.encrypt_and_sign(current_instructeur.email, purpose: :reset_link, expires_in: 1.hour)
    redirect_to link_sent_path(email: signed_email)
  end

  def link_sent
    email = message_encryptor_service.decrypt_and_verify(params[:email], purpose: :reset_link) rescue nil

    if StrictEmailValidator::REGEXP.match?(email)
      @email = email
    else
      redirect_to root_path
    end
  end

  # DELETE /resource/sign_out
  def destroy
    if user_signed_in?
      pro_connect_id_token = current_user&.instructeur&.pro_connect_id_token

      current_user.update(loged_in_with_france_connect: nil)
      current_user&.instructeur&.update(pro_connect_id_token: nil)

      sign_out :user

      delete_pro_connect_session_info_cookie

      if logged_in_with_france_connect?
        return redirect_to france_connect_logout_url(callback: root_url), allow_other_host: true
      end

      if pro_connect_id_token.present?
        return redirect_to ProConnectService.logout_url(pro_connect_id_token, host_with_port: request.host_with_port),
          allow_other_host: true
      end
    end

    respond_to_on_destroy
  end

  def no_procedure
    clear_stored_location_for(:user)
    redirect_to new_user_session_path
  end

  def sign_in_by_link
    instructeur = Instructeur.find(params[:id])
    trusted_device_token = instructeur
      .trusted_device_tokens
      .find_by(token: params[:jeton])

    if trusted_device_token.nil?
      flash[:alert] = 'Votre lien est invalide.'

      redirect_to root_path
    elsif trusted_device_token.token_valid?
      trust_device(trusted_device_token.created_at, trusted_device_token)

      period = ((trusted_device_token.created_at + TRUSTED_DEVICE_PERIOD) - Time.zone.now).to_i / ActiveSupport::Duration::SECONDS_PER_DAY

      flash.notice = "Merci d’avoir confirmé votre connexion. Votre navigateur est maintenant authentifié pour #{period} jours."

      # redirect to procedure'url if stored by store_location_for(:user) in dossiers_controller
      # redirect to root_path otherwise

      if instructeur_signed_in?
        current_user.update!(email_verified_at: Time.zone.now)

        redirect_to after_sign_in_path_for(:user)
      else
        redirect_to new_user_session_path
      end
    else
      flash[:alert] = 'Votre lien est expiré, un nouveau vient de vous être envoyé.'

      send_login_token_or_bufferize(instructeur)
      signed_email = message_encryptor_service.encrypt_and_sign(instructeur.email, purpose: :reset_link, expires_in: 1.hour)
      redirect_to link_sent_path(email: signed_email)
    end
  end

  # Pro connect callback
  def logout
    redirect_to root_path, notice: I18n.t('devise.sessions.signed_out')
  end

  def redirect_to_pro_connect_if_mandatory
    return if !ProConnectService.enabled?

    return if !ProConnectService.email_domain_is_in_mandatory_list?(user_email_params[:email])

    flash[:alert] = "La connexion des agents passe à présent systématiquement par ProConnect"
    redirect_to pro_connect_path(force_pro_connect: true)
  end

  # calling current_user in a before_action will trigger the warden authentication (devise behavior)
  # which is not what we want in a before_action of a sign_in action (current_user should be nil before explicit sign_in)
  # so we need to override current_user to avoid this
  # https://github.com/heartcombo/devise/issues/5602#issuecomment-1876164084
  def current_user
    super if warden.authenticated?(scope: :user)
  end

  private

  def user_email_params
    params.require(:user).permit(:email)
  end

  def user_password_params
    params.require(:user).permit(:password)
  end
end
