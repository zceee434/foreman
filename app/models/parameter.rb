class Parameter < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name
  include Parameterizable::ByIdName
  include HiddenValue

  validates_lengths_from_database

  include Authorizable
  validates :name, :presence => true, :no_whitespace => true

  scoped_search :on => :name, :complete_value => true
  scoped_search :on => :type, :complete_value => true
  scoped_search :on => :value, :complete_value => true

  # children associations must be defined here, otherwise scoped search definitions won't find them
  belongs_to :domain, :foreign_key => :reference_id, :inverse_of => :domain_parameters
  belongs_to :operatingsystem, :foreign_key => :reference_id, :inverse_of => :os_parameters
  belongs_to :subnet, :foreign_key => :reference_id, :inverse_of => :subnet_parameters
  belongs_to_host :foreign_key => :reference_id, :inverse_of => :host_parameters
  belongs_to :hostgroup, :foreign_key => :reference_id, :inverse_of => :group_parameters
  belongs_to :location, :foreign_key => :reference_id, :inverse_of => :location_parameters
  belongs_to :organization, :foreign_key => :reference_id, :inverse_of => :organization_parameters
  # specific children search definitions, required for permission filters autocompletion
  scoped_search :in => :domain, :on => :name, :complete_value => true, :rename => 'domain_name'
  scoped_search :in => :operatingsystem, :on => :name, :complete_value => true, :rename => 'os_name'
  scoped_search :in => :subnet, :on => :name, :complete_value => true, :rename => 'subnet_name'
  scoped_search :in => :host, :on => :name, :complete_value => true, :rename => 'host_name'
  scoped_search :in => :hostgroup, :on => :name, :complete_value => true, :rename => 'host_group_name'
  if Taxonomy.locations_enabled
    scoped_search :in => :location, :on => :name, :complete_value => true, :rename => 'location_name'
  end
  if Taxonomy.organizations_enabled
    scoped_search :in => :organization, :on => :name, :complete_value => true, :rename => 'organization_name'
  end

  default_scope -> { order("parameters.name") }

  before_create :set_priority

  PRIORITY = { :common_parameter => 0,
               :organization_parameter => 10,
               :location_parameter => 20,
               :domain_parameter => 30,
               :subnet_parameter => 40,
               :os_parameter => 50,
               :group_parameter => 60,
               :host_parameter => 70
             }

  def self.type_priority(type)
    PRIORITY.fetch(type.to_s.underscore.to_sym, nil) unless type.nil?
  end

  private

  def set_priority
    self.priority = Parameter.type_priority(type)
  end

  def skip_strip_attrs
    ['value']
  end
end
