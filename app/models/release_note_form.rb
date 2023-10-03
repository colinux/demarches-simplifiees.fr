class ReleaseNoteForm
  include ActiveModel::Model

  attr_writer :release_notes
  attr_reader :released_on, :published
  attr_accessor :group

  validates :group, presence: true
  validates :released_on, presence: true

  def release_notes
    @release_notes ||= []
  end

  def assign_notes_and_attributes(notes, attributes)
    self.release_notes = notes.to_a
    self.attributes = attributes
  end

  def released_on=(value)
    @released_on = if value.is_a?(String)
      Date.parse(value) rescue nil
    else
      value
    end

    release_notes.each { _1.released_on = @released_on }
  end

  def published=(value)
    @published = value

    release_notes.each { _1.published = value }
  end

  def release_notes_attributes=(attributes)
    attributes.values.each do |attrs|
      if attrs[:id].present?
        note = @release_notes.find { _1.id.to_s == attrs[:id].to_s }
        note&.assign_attributes(attrs.except(:id))
      else
        release_notes.push ReleaseNote.new(attrs.merge(released_on: released_on, published: published, group: group))
      end
    end
  end

  def save
    if valid?
      ReleaseNote.transaction do
        @release_notes.each(&:save!)
      end
    else
      @release_notes.each do |note|
        note.errors.each do |error|
          errors.import(error)
        end
      end
      false
    end
  end

  def valid?
    super && @release_notes.all?(&:valid?)
  end

  def persisted?
    release_notes.first.persisted?
  end

  def model_name
    ActiveModel::Name.new(ReleaseNote)
  end
end
