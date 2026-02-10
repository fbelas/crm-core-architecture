class Onepharma::Department < Onepharma::Customer
=begin
    (TABLE_OF_VALUE)
    CUSTOMER_TYPE (department.type):
        1 => "Serviço"
        2 => "Comissão"
        9999 => "Temporário"
    CUSTOMER_SUB_TYPE (department.sub_type):
        1-... => Vários subtipos de serviços associados

    FIRST_NAME = NOME da INST
    LAST_NAME = NOME do DEPT que vai seguir para crm
    FULL_NAME = CONCAT (FIRST LAST)
    ALTERNATIVE_NAME = opcional? não está preenchido em  todos
    SHORT_NAME = opcional? abrev de cada palavra
=end
    include LoggableConcern

    FIELDS_TO_FILTER_LIST = %w{FULL_NAME STATUS UPDATE_DATE TYPE SUB_TYPE}.freeze

    default_scope {where(CUSTOMER_FILE: :DEPT)}

    scope :by_active, -> {where(STATUS: ["ACTV"]).order(FULL_NAME: :asc)}

    has_many :prof_dept_affiliations, foreign_key: :to_customer_id, dependent: :destroy
    has_many :professionals, through: :prof_dept_affiliations

    has_many :dept_inst_affiliations, foreign_key: :from_customer_id, dependent: :destroy
    has_many :institutions, through: :dept_inst_affiliations

    validate :validate_customer_type_inclusion
    validate :validate_customer_sub_type_inclusion

    before_validation :set_auto_fields

    after_update :update_affiliation_fields#, :set_customer_update_date

    def institution
        institutions[0]
    end

    def get_professional_affiliation_from_department(customer_id)
        self.prof_dept_affiliations.where(FROM_CUSTOMER_ID: customer_id)[0]
    end

    def dept_inst_affiliation
        dept_inst_affiliations[0]
    end

    def get_department_affiliation(institution_id)
        #Para lidar com uma situaçã oem que o mesmo id de dpt está a aparecer em insts diferentes devido a registos antigos
        self.dept_inst_affiliations.where(TO_CUSTOMER_ID: institution_id).pluck(:AFFILIATION_ID)
    end

    private
    def validate_customer_type_inclusion
        unless Onepharma::TableOfValue.where(CODE_ROLE: 'department.type', EXCLUDE: nil).pluck(:code).include?(self.CUSTOMER_TYPE)
            errors.add(:CUSTOMER_TYPE, :inclusion, value: self.CUSTOMER_TYPE)
        end
    end

    def validate_customer_sub_type_inclusion
        unless Onepharma::TableOfValue.where(CODE_ROLE: 'department.sub_type', EXCLUDE: nil).pluck(:code).include?(self.CUSTOMER_SUB_TYPE)
            errors.add(:CUSTOMER_SUB_TYPE, :inclusion, value: self.CUSTOMER_SUB_TYPE)
        end
    end

    def set_auto_fields
        #logica de preenchimento - ver os dados acima
        #Ao haver change no costumer_sub_type vai receber o valor da select2, será um id ou um str
        #vai despois procurar pr esse valor no TableOfValue
        #se sub_type existir faz as condições, se não assume o serviço geral "43" como o padrão e coloca um last_name com o input

        if CUSTOMER_SUB_TYPE_changed? && self[:CUSTOMER_SUB_TYPE].present?
            sub_type = Onepharma::TableOfValue.where(CODE_ROLE: 'department.sub_type', EXCLUDE: nil, CODE: self[:CUSTOMER_SUB_TYPE])[0]
            if sub_type.blank?
                self.LAST_NAME = self[:CUSTOMER_SUB_TYPE].upcase
                self[:CUSTOMER_SUB_TYPE] = "43"
            else
                self.LAST_NAME =  Onepharma::TableOfValue.where(CODE_ROLE: 'department.sub_type', EXCLUDE: nil).where(CODE: sub_type.CODE)[0].DESCRIPTION
            end

            self.FULL_NAME  = "#{self.LAST_NAME}(#{self.FIRST_NAME})"
        end
    end

    def update_affiliation_fields
        self.prof_dept_affiliations.update_all(TO_NAME: "#{self.FIRST_NAME} - #{self.LAST_NAME}")
    end


=begin
    def set_customer_update_date
        if self.previous_changes.any?
          institution = self.institution
          if institution
            institution.UPDATE_DATE = Time.now
            institution.save!
          end
        end
    end
=end

end
