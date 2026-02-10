class Onepharma::DeptInstAffiliation < Onepharma::Affiliation
=begin
    AFFILIATION_TYPE INST
    FROM_CUSTOMER_ID - :department
    TO_CUSTOMER_ID - :institution
=end
    include LoggableConcern
    default_scope {where(AFFILIATION_TYPE: :INST)}

    belongs_to :department, foreign_key: "FROM_CUSTOMER_ID", optional: true # BUG TINY TDS, usa offset para validar
    belongs_to :institution, foreign_key: "TO_CUSTOMER_ID", optional: true # BUG TINY TDS, usa offset para validar

    after_save :update_customer_date

    private

    def update_customer_date
        Onepharma::Institution.where(CUSTOMER_ID: self.TO_CUSTOMER_ID)[0].touch
    end
end
