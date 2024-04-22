require 'rubocop/rspec/support'
# require 'rubocop/rspec/cop_helper'
require_relative '../../lib/cops/user_email_for'

RSpec.describe RuboCop::Cop::DS::UserEmailFor do
  # subject(:cop) { described_class.new }

  it 'registers an offense when using dossier.user.email' do
    expect_offense(<<~RUBY)
      dossier.user.email
      ^^^^^^^^^^^^^^^^^ Utilisez `dossier.user_email_for` au lieu de `dossier.user.email`.
    RUBY
  end

  it 'registers an offense when using instructeur.dossiers.first.user.email' do
    expect_offense(<<~RUBY)
      instructeur.dossiers.first.user.email
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Utilisez `dossier.user_email_for` au lieu de `dossier.user.email`.
    RUBY
  end

  it 'does not register an offense inside the user_email_for method definition' do
    expect_no_offenses(<<~RUBY)
      def user_email_for
        dossier.user.email
      end
    RUBY
  end
end
