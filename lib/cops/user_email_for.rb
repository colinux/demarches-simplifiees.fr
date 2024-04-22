# frozen_string_literal: true

module RuboCop
  module Cop
    module DS
      class UserEmailFor < Cop
        MSG = 'Utilisez `dossier.user_email_for` au lieu de `dossier.user.email`.'

        def_node_matcher :user_email_access?, <<~PATTERN
          (send (send nil? :user) :email)
        PATTERN

        def_node_search :inside_user_for_email?, <<~PATTERN
          (def :user_for_email ...)
        PATTERN

        def on_send(node)
          # return if inside_user_for_email?(node.ancestors.first)
          user_email_access?(node) do |_matcher|
            add_offense(node, message: MSG)
          end
        end
      end
    end
  end
end if defined?(RuboCop)
