# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/administrateur_mailer
class AdministrateurMailer < ApplicationMailer
  layout 'mailers/layout'

  def activate_before_expiration(user, reset_password_token)
    @user = user
    @reset_password_token = reset_password_token
    @expiration_date = @user.reset_password_sent_at + Devise.reset_password_within
    @subject = "N'oubliez pas d’activer votre compte administrateur"

    bypass_unverified_mail_protection!

    configure_defaults_for_user(user)
    mail(to: user.email,
      subject: @subject,
      reply_to: CONTACT_EMAIL)
  end

  def notify_procedure_expires_when_termine_forced(user_email, procedure)
    @procedure = procedure
    @subject = "La suppression automatique des dossiers a été activée sur la démarche #{procedure.libelle}"

    configure_defaults_for_email(user_email)
    mail(to: user_email,
      subject: @subject,
      reply_to: CONTACT_EMAIL)
  end

  def notify_service_without_siret(user_email)
    @subject = "Siret manquant sur un de vos services"

    configure_defaults_for_email(user_email)
    mail(to: user_email,
      subject: @subject,
      reply_to: CONTACT_EMAIL)
  end

  def api_token_expiration(user, tokens)
    @subject = "Renouvellement de jeton d'API nécessaire"
    @tokens = tokens

    configure_defaults_for_user(user)
    mail(to: user.email,
      subject: @subject,
      reply_to: CONTACT_EMAIL)
  end

  def self.critical_email?(action_name)
    action_name == "activate_before_expiration"
  end
end
