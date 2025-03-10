# frozen_string_literal: true

if defined?(RuboCop)
  module RuboCop
    module Cop
      module DS
        class ApplicationName < Base
          MSG = "Avoid hardcoding `demarches-simplifiees.fr`. Instead use a dedicated environnement variable."
          def on_str(node)
            return unless node.source.include?('demarches-simplifiees.fr')

            add_offense(node)
          end
        end
      end
    end
  end
end
