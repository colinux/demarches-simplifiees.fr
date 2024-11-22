# frozen_string_literal: true

class WarnUnverifiedEmailComponentPreview < ViewComponent::Preview
  def default
    render(WarnUnverifiedEmailComponent.new)
  end
end
