class Onepharma::Professional < Onepharma::Customer
=begin
    (TABLE_OF_VALUE)
    CUSTOMER_TYPE (person.type):
        1 => "Médico"
        2 => "Paramédico"
        3 => "Farmaceutico"
        90 => "Utilizador"

    CUSTOMER_SUB_TYPE (person.sub_type):
        1 - 12 => ""
        21 - 23 => ""
        90 => ""

=end
    include LoggableConcern
    include ProfessionalExtraction
    include TicketableProfessional

    self.table_name = 'op.customer'

    default_scope {where(CUSTOMER_FILE: :PRES)}

    HELPER_PROFESSIONAL_TYPE_LIST= {
        1 => "Médico",
        2 => "Paramédico",
        3 => "Farmaceutico",
        90 => "Utilizador"
    }.freeze



    has_many :prof_dept_affiliations, foreign_key: :from_customer_id, dependent: :destroy
    has_many :departments, through: :prof_dept_affiliations
    has_many :active_affiliation_departments, ->{where(affiliation: {STATUS: ["ACTV", "DVLP"]})}, through: :prof_dept_affiliations, source: :department

    has_many :dept_inst_affiliations, through: :departments
    has_many :institutions, through: :dept_inst_affiliations
    has_many :professional_details, foreign_key: 'CUSTOMER_ID', dependent: :destroy

    has_many :specialties, -> { where(customer_specialty: {STATUS: ["ACTV", "DVLP"]})}, foreign_key: 'CUSTOMER_ID', dependent: :destroy
    accepts_nested_attributes_for :specialties
    accepts_nested_attributes_for :professional_details

    has_many :competencies, -> { where(customer_specialty: {STATUS: ["ACTV", "DVLP"]})}, foreign_key: 'CUSTOMER_ID', dependent: :destroy

    has_many :contacts, foreign_key: 'CUSTOMER_ID', dependent: :destroy

    validate :validate_customer_type_inclusion
    validate :validate_customer_sub_type_inclusion
    #validates :FIRST_NAME, :LAST_NAME, :SHORT_NAME, :FULL_NAME, presence: true, format: {
    #    without: /[´`ºª~^;,çÇ!?"#{}[]=+*_+¨£§$%]/,
    #    message: I18n.t("alerts.check_special_characters")
    #  }

    validates :CUSTOMER_TYPE, :CUSTOMER_SUB_TYPE, presence: true
    validates :EXTERNAL_ID_1, presence: true, format: {
        with: /\A[A-Za-z0-9\-\.\/ ]+\z/,
        message: I18n.t("alerts.check_special_characters")
    }
    validates :FIRST_NAME, :LAST_NAME, :FULL_NAME, :SHORT_NAME, presence: true, format: {
        with: /\A[A-Z0-9\s.\-\/]*\z/,
        message: I18n.t("alerts.check_special_characters")
      }

    before_validation :set_auto_fields
    before_save :set_update_date

    before_create :set_status
    before_update :onepharma_status_logic

    scope :by_active, -> {
                        where(STATUS: ["ACTV", "DVL"]).order(FULL_NAME: :asc)}

    scope :by_active_last_update_one_year_ago, -> {
                        where(STATUS: ["ACTV", "DVL"])
                            .where("UPDATE_DATE <= ? OR UPDATE_DATE IS NULL", 2.year.ago.to_date)
                            .order(UPDATE_DATE: :asc)
                        }

    def load_affiliation_info
        affiliation_info = Onepharma::Professional.find_by_sql([%{
            SELECT pda.STATUS, pda.COMPANY_DB_OWNER, pda.AFFILIATION_ROLE_1, LAST_NAME FROM [op].[affiliation]  dia
                INNER JOIN [op].[customer]
                    ON dia.[from_customer_id] = [op].[customer].[CUSTOMER_ID]
                INNER JOIN [op].[affiliation] pda
                    ON [op].[customer].[CUSTOMER_ID] = pda.[TO_CUSTOMER_ID]
                WHERE [op].[customer].[CUSTOMER_FILE] = 'DEPT' AND dia.[AFFILIATION_TYPE] = 'Inst'
                AND pda.[from_customer_id] = ?
        }, self.CUSTOMER_ID])
    end

    def self.search_with options
        filter_query = self
        if options[:num_ordem].present?
            if options[:num_ordem].include? "*"#para pesquisar valores especificos entre *
                search_string = options[:num_ordem].gsub('*', '%')
                filter_query =  filter_query.where("EXTERNAL_ID_1 LIKE ?", "#{search_string}")
            else
                filter_query =  filter_query.where("EXTERNAL_ID_1 = ?", "#{options[:num_ordem]}")
            end
        elsif options[:customer_id].present?
            if options[:customer_id].include? "*"#para epsquisar valores especificos entre *
                search_string = options[:customer_id].gsub('*', '%')
                filter_query =  filter_query.where("CUSTOMER_ID LIKE ?", "#{search_string}")
            else
                filter_query =  filter_query.where("CUSTOMER_ID = ?", "#{options[:customer_id]}")
            end
        else
            if options[:full_name].present?
                options[:full_name].split.each do |name|
                    filter_query = filter_query.where("op.CUSTOMER.FULL_NAME LIKE ?", "%#{name}%")
                end
            end

            if options[:specialty].present?
                filter_query = filter_query.joins(:specialties).where(CUSTOMER_SPECIALTY:{SPECIALTY: options[:specialty]})
            end
        end

        # tenho de fazer uma segunda query para obter todos os dados do Medico, incluindo as outras respectivas especialidada a mais da filtrada
        result = self.left_joins(:specialties)
                    .joins("LEFT JOIN optov.table_of_value on CODE_ROLE = 'person.specialty_tmp' and CODE = SPECIALTY")
                    .select(:CUSTOMER_ID, :FULL_NAME,:EXTERNAL_ID_1)
                    .select("description as specialty")
                    .where(CUSTOMER_ID: filter_query.pluck(:CUSTOMER_ID))
                    .where(STATUS: ["ACTV", "DVL"])
                    .order("CUSTOMER.FULL_NAME ASC")
        result
    end

    def self.index_search_with options
        filter_query = self
        if options[:num_ordem].present?
            if options[:num_ordem].include? "*"#para epsquisar valores especificos entre *
                search_string = options[:num_ordem].gsub('*', '%')
                filter_query =  filter_query.where("EXTERNAL_ID_1 LIKE ?", "#{search_string}")
            else
                filter_query =  filter_query.where("EXTERNAL_ID_1 = ?", "#{options[:num_ordem]}")
            end
        elsif options[:customer_id].present?
            if options[:customer_id].include? "*"#para epsquisar valores especificos entre *
                search_string = options[:customer_id].gsub('*', '%')
                filter_query =  filter_query.where("CUSTOMER_ID LIKE ?", "#{search_string}")
            else
                filter_query =  filter_query.where("CUSTOMER_ID = ?", "#{options[:customer_id]}")
            end
        else
            if options[:full_name].present?
                options[:full_name].split.each do |name|
                    filter_query = filter_query.where("op.CUSTOMER.FULL_NAME LIKE ?", "%#{name}%")
                end
            end

            if options[:specialty].present?
                filter_query = filter_query.joins(:specialties).where(CUSTOMER_SPECIALTY:{SPECIALTY: options[:specialty]})
            end
        end

        # tenho de fazer uma segunda query para obter todos os dados do Medico, incluindo mais do que a especialidada filtrada
        result = self.left_joins(:specialties)
                    .joins("LEFT JOIN optov.table_of_value on CODE_ROLE = 'person.specialty_tmp' and CODE = SPECIALTY")
                    .select(:CUSTOMER_ID, :STATUS, :FULL_NAME,:EXTERNAL_ID_1)
                    .select("description as specialty")
                    .where(CUSTOMER_ID: filter_query.pluck(:CUSTOMER_ID))
                    .order("op.customer_specialty.SPECIALTY_RANK ASC")

        result
    end

    private

    def set_update_date
        self.UPDATE_DATE = Time.now if self.changed?
    end

    def set_status
        #ACTV - 7 "Válido - 100%"
        self.STATUS_CHANGE_REASON = "7"
    end

    def set_auto_fields
        if self.FIRST_NAME_changed? || self.LAST_NAME_changed?
            self.FULL_NAME  = "#{self.FIRST_NAME} #{self.LAST_NAME}"
        end
    end

    #def strip_strings
    #    self.FIRST_NAME = self.FIRST_NAME.strip if self.FIRST_NAME_changed?
    #    self.LAST_NAME = self.LAST_NAME.strip if self.LAST_NAME_changed?
    #    self.EXTERNAL_ID_1 = self.EXTERNAL_ID_1.strip if self.EXTERNAL_ID_1_changed?
    #    self.SHORT_NAME = self.SHORT_NAME.strip if self.SHORT_NAME_changed?
    #end

    def validate_customer_type_inclusion
        unless Onepharma::TableOfValue.where(CODE_ROLE: 'person.type').pluck(:code).include?(self.CUSTOMER_TYPE)
            errors.add(:CUSTOMER_TYPE, :inclusion, value: self.CUSTOMER_TYPE)
        end
    end

    def validate_customer_sub_type_inclusion
        unless Onepharma::TableOfValue.where(CODE_ROLE: 'person.sub_type').pluck(:code).include?(self.CUSTOMER_SUB_TYPE)
            errors.add(:CUSTOMER_SUB_TYPE, :inclusion, value: self.CUSTOMER_SUB_TYPE)
        end
    end

    def onepharma_status_logic
=begin  #customer.rb
        STATUS_LIST = %w{ACTV DUPL DVLP INAC}.freeze
        VALIDATION_STATUS_LIST = %w{INVL NEW VALD}.freeze
        #
        ACTV
        1	Inválido - Baixa Prolongada
        3	Inválido - Local Trabalho Inactivo
        5	Inválido - Reformado
        6	Inválido - Regressou ao país de Origem
        7	Válido - 100%
        8	Válido - Dados Corrigidos
        10	Inválido - A Exercer fora do País
        11	Inválido - Baixa

        #Acrescento à parte
        12 Válido - Reformado
        DUPL
        9	Inválido - Duplicado

        DVLP
        2	Inválido - Dados Incompletos

        INAC
        4	Inválido - Morte


=end
        # Não existe STATUS_CHANGE_REASON na opdb que permita deduzir o STATUS para reformado activo
        # estou a criar essa opção à parte com base no que deve ser guardado no opdb - 12 na lista de opções
        if self.STATUS_CHANGE_REASON == "12"
            self.STATUS = "ACTV"
            self.STATUS_CHANGE_REASON = "5"
        elsif self.STATUS_CHANGE_REASON == "5"
            self.STATUS = "INAC"
        else
        self.STATUS =
            case self.STATUS_CHANGE_REASON
            when "2"
                "DVLP"
            when "1", "3", "7", "8", "11"
                "ACTV"
            when "9"
                "DUPL"
            else
                "INAC"
            end
        end
        self.VALIDATION_STATUS = "VALD"
    end

end
