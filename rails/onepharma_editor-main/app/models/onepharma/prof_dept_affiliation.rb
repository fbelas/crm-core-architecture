class Onepharma::ProfDeptAffiliation < Onepharma::Affiliation
=begin
    #AFFILIATION_TYPE: :DEPT

    FROM_CUSTOMER_ID - :professional
    TO_CUSTOMER_ID - :department

    Table_of_value
    person.affiliation_role = cargo
=end
    include LoggableConcern

    default_scope {where(AFFILIATION_TYPE: :DEPT)}

    scope :by_active, -> {where(STATUS: ["ACTV"]).order(FULL_NAME: :asc)}
    scope :active, -> {where(STATUS: ["ACTV", "DVL"])}

    scope :by_active_affiliation_main , -> {where(STATUS: ["ACTV"])}

    belongs_to :professional, foreign_key: "FROM_CUSTOMER_ID", optional: true # BUG TINY TDS, usa offset para validar
    belongs_to :department, foreign_key: "TO_CUSTOMER_ID",  optional: true # BUG TINY TDS, usa offset para validar

    validates :TO_CUSTOMER_ID, :FROM_CUSTOMER_ID, :AFFILIATION_ROLE_1, presence: true

    before_validation do |obj|
        department = Onepharma::Department.where(CUSTOMER_ID: obj.TO_CUSTOMER_ID)[0]
        if(department.present?)
            obj.TO_NAME = "#{department.FIRST_NAME} - #{department.LAST_NAME}"
        end
    end

    before_save :normalize_affiliation_main

    after_save :update_customer_date
    before_save :check_and_update_last_status_change

    after_create :default_affiliation_main

    private

    def normalize_affiliation_main
        return unless self.AFFILIATION_MAIN == 1
        @professional = Onepharma::Professional.where(CUSTOMER_ID: self.FROM_CUSTOMER_ID)[0]
        @departments = @professional.prof_dept_affiliations.update_all(AFFILIATION_MAIN: 0)
    end

    def update_customer_date
        Onepharma::Professional.where(CUSTOMER_ID: self.FROM_CUSTOMER_ID)[0].touch
    end

    def default_affiliation_main
        @professional = Onepharma::Professional.where(CUSTOMER_ID: self.FROM_CUSTOMER_ID)[0]
        active_aff = @professional.prof_dept_affiliations.by_active_affiliation_main
        if (active_aff.count == 1)
            active_aff.update_all(AFFILIATION_MAIN: 1)
        end
    end

    def check_and_update_last_status_change
        if self.STATUS_changed?
            self.STATUS_CHANGE_DATE = Time.now
        end
    end

end
