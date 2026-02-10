class Onepharma::Institution < Onepharma::Customer
=begin
    (TABLE_OF_VALUE)
    CUSTOMER_TYPE (institution.sub_type):
        1 => "Público"
        2 => "Privado"
        3 => "Parceria Publico-Privada"
        ...

    CUSTOMER_SUB_TYPE (institution.type):
        1 - 90 => EX:"Instituto", "Bombeiros", "Hospital"

=end
    include LoggableConcern
    include InstitutionExtraction
    include TicketableInstitution

    self.table_name = 'op.customer'

    SUB_TYPE_LIST = %w{ACTV DUPL DVLP INAC}.freeze

    default_scope {where(CUSTOMER_FILE: :INST)}
    #scope :by_active, -> {where(STATUS: ["ACTV"])}
    scope :by_active, -> {where(STATUS: ["ACTV","DVL"]).order(FULL_NAME: :asc)}

    has_many :dept_inst_affiliations, foreign_key: "TO_CUSTOMER_ID", dependent: :destroy
    has_many :departments, through: :dept_inst_affiliations, dependent: :destroy

    has_many :addresses, foreign_key: 'CUSTOMER_ID', dependent: :destroy
    accepts_nested_attributes_for :addresses, allow_destroy: true, update_only: true

    has_many :contacts, foreign_key: 'CUSTOMER_ID', dependent: :destroy
    has_many :institution_info, foreign_key: 'CUSTOMER_ID', dependent: :destroy

    #validate :validate_customer_type_inclusion
    #validate :validate_customer_sub_type_inclusion

    before_validation :set_auto_fields

    validate do |a|
        validate_customer_type_inclusion
        validate_customer_sub_type_inclusion
    end
    #validates :FIRST_NAME, :LAST_NAME, :FULL_NAME, presence: true
    validates :FIRST_NAME, :LAST_NAME, :FULL_NAME, :SHORT_NAME, presence: true, format: {
        with: /\A[A-Z0-9\s,.()\-\/]*\z/,
        message: I18n.t("alerts.check_special_characters")
      }

    before_save :set_update_date

    before_create :set_status
    before_update :onepharma_status_logic

    after_create do |obj|
        @new_department = Onepharma::Department.create(FIRST_NAME: obj.FULL_NAME, LAST_NAME: "Geral", CUSTOMER_TYPE: '1', CUSTOMER_SUB_TYPE: '43')
        Onepharma::DeptInstAffiliation.create(FROM_CUSTOMER_ID: @new_department.CUSTOMER_ID, TO_CUSTOMER_ID: obj.CUSTOMER_ID, TO_NAME: @new_department.FULL_NAME)
    end

    after_update do |obj|
        if obj.saved_change_to_FULL_NAME?
            #actualiza o nome de todas as relaçãoes caso tenha sido alterado na instituição
            #update departments
            departments = obj.departments.includes(:dept_inst_affiliations, :prof_dept_affiliations)
            departments.update_all("FIRST_NAME = '#{obj.FULL_NAME}', FULL_NAME = LAST_NAME + '(' + '#{obj.FULL_NAME}' + ')'")

            #update das affiliations
            departments.each do |dept|
              dept.dept_inst_affiliations.update_all(TO_NAME: "#{dept.LAST_NAME}(#{obj.FULL_NAME})")
              Onepharma::ProfDeptAffiliation.where(TO_CUSTOMER_ID: dept.CUSTOMER_ID).update_all(TO_NAME: "#{dept.FIRST_NAME} - #{dept.LAST_NAME}")
            end
        end
    end

    def address
        addresses[0]
    end

    def get_full_cp
        address = self.address
        return unless address.present?
        cp_4_3 = address&.PA_CP4 + "-" + address&.PA_CP3
        return cp_4_3
    end

    def self.index_search_with options
        filter_query = self

        if options[:customer_id].present?
            if options[:customer_id].include? "*"#para pesquisar valores especificos entre *
                search_string = options[:customer_id].gsub('*', '%')
                filter_query =  filter_query.where("CUSTOMER_ID LIKE ?", "#{search_string}")
            else
                filter_query =  filter_query.where("CUSTOMER_ID = ?", "#{options[:customer_id]}")
            end
        else
            if options[:line_address_1].present?
                options[:line_address_1].split.each do |address|
                    filter_query = filter_query.joins(:addresses).where("op.CUSTOMER_ADDRESS.LINE_ADDRESS_1 LIKE ?", "%#{address}%")
                end
            end
            if options[:cp].present?
                filter_query = filter_query.joins(:addresses).where("(op.CUSTOMER_ADDRESS.PA_CP4 + '-' + op.CUSTOMER_ADDRESS.PA_CP3) LIKE ?", "%#{options[:cp]}%")
            end

            if options[:full_name].present?
                options[:full_name].split.each do |name|
                    filter_query = filter_query.where("op.CUSTOMER.FULL_NAME LIKE ?", "%#{name}%")
                end
            end

            if options[:pa_city].present?
                options[:pa_city].split.each do |city|
                    filter_query = filter_query.joins(:addresses).where("op.CUSTOMER_ADDRESS.PA_CITY LIKE ?", "%#{city}%")
                end
            end

        end

        # tenho de fazer uma segunda query para obter todos os dados do Medico, incluindo mais do que a especialidada filtrada
        result = self
                    .joins("LEFT JOIN op.CUSTOMER_ADDRESS ON CUSTOMER.CUSTOMER_ID = op.CUSTOMER_ADDRESS.CUSTOMER_ID")
                    #.select("CUSTOMER.CUSTOMER_ID, CUSTOMER.FULL_NAME, CUSTOMER.STATUS, CUSTOMER.CUSTOMER_TYPE, CUSTOMER.CUSTOMER_SUB_TYPE")
                    .select("CUSTOMER.CUSTOMER_ID, CUSTOMER.FULL_NAME, CUSTOMER.STATUS, CUSTOMER.CUSTOMER_TYPE, CUSTOMER.CUSTOMER_SUB_TYPE")
                    .where(CUSTOMER_ID: filter_query.pluck(:CUSTOMER_ID))
                    .where("op.CUSTOMER_ADDRESS.STATUS = ?", 'ACTV')
                    .order("CUSTOMER.FULL_NAME ASC")

        return result
    end

    private
    def validate_customer_type_inclusion
        unless Onepharma::TableOfValue.where(CODE_ROLE: 'institution.type').pluck(:code).include?(self.CUSTOMER_TYPE)
            errors.add(:CUSTOMER_TYPE, :inclusion, value: self.CUSTOMER_TYPE)
        end
    end

    def validate_customer_sub_type_inclusion
        unless Onepharma::TableOfValue.where(CODE_ROLE: 'institution.sub_type').pluck(:code).include?(self.CUSTOMER_SUB_TYPE)
            errors.add(:CUSTOMER_SUB_TYPE, :inclusion, value: self.CUSTOMER_SUB_TYPE)
        end
    end

    def set_auto_fields
        self.FIRST_NAME = '.'
        self.LAST_NAME = '.'
        self.SHORT_NAME = self.FULL_NAME
    end

    def set_status
        #ACTV - 7 "Válido - 100%"
        self.STATUS_CHANGE_REASON = "7"
    end

    def set_update_date
        self.UPDATE_DATE = Time.now if self.changed?
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

        DUPL
        9	Inválido - Duplicado

        DVLP
        2	Inválido - Dados Incompletos

        INAC
        4	Inválido - Morte

=end
        self.STATUS =
            case self.STATUS_CHANGE_REASON
            when "2"
                "DVLP"
            when "7", "8", "1", "5", "6", "7", "8", "10", "11"
                "ACTV"
            when "9"
                "DUPL"
            else
                "INAC"
            end

        self.VALIDATION_STATUS = "VALD"
    end

end
