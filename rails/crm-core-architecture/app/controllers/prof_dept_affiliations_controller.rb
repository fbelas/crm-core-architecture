class ProfDeptAffiliationsController < BackofficeController
    before_action :get_lists, except: [:institution_add_new_prof_dept_affiliation]

    layout "backoffice"

    def create
        @institution = Onepharma::Institution.where(CUSTOMER_ID: params[:institution_id])[0]
        @department = Onepharma::Department.where(CUSTOMER_ID: params[:onepharma_prof_dept_affiliation][:TO_CUSTOMER_ID])[0]

        @new_prof_dept_affiliation = Onepharma::ProfDeptAffiliation.create(prof_dept_affiliation_params)
        @professional = Onepharma::Professional.where(CUSTOMER_ID: params[:onepharma_prof_dept_affiliation][:FROM_CUSTOMER_ID])[0]

        if @new_prof_dept_affiliation.valid?
            @departments_list_hash = @professional.departments.index_by(&:CUSTOMER_ID)
            flash.now[:success] = I18n.t("alerts.records.prof_dept_affiliation_created")
        else
            @new_prof_dept_affiliation = Onepharma::ProfDeptAffiliation.new(prof_dept_affiliation_params)
            @institution_departments_list_for_select = @institution.departments.by_active.pluck(:FULL_NAME, :CUSTOMER_ID)
            flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
        end
    end

    def create_through_institution
        #FROM_CUSTOMER_ID - :professional
        #TO_CUSTOMER_ID - :department

        @department = Onepharma::Department.where(CUSTOMER_ID: params[:onepharma_prof_dept_affiliation][:TO_CUSTOMER_ID])[0]
        @institution = @department.institution

        @new_prof_dept_affiliation = Onepharma::ProfDeptAffiliation.create(prof_dept_affiliation_params)
        @professional = Onepharma::Professional.where(CUSTOMER_ID: params[:onepharma_prof_dept_affiliation][:FROM_CUSTOMER_ID])[0]

        if @new_prof_dept_affiliation.valid?
            @departments_list_hash = @professional.departments.index_by(&:CUSTOMER_ID)
            #@professionals_from_department_ids = (params[:professionals_from_department_ids] << @professional.CUSTOMER_ID.to_s)

            flash.now[:success] = I18n.t("alerts.records.prof_dept_affiliation_created")
        else
            @new_prof_dept_affiliation = Onepharma::ProfDeptAffiliation.new(prof_dept_affiliation_params)
            @institution_departments_list_for_select = @institution.departments.pluck(:FULL_NAME, :CUSTOMER_ID)
            flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
        end
    end

    def edit
        @prof_dept_affiliation = Onepharma::ProfDeptAffiliation.where(AFFILIATION_ID: params[:id])[0]
        @professional = Onepharma::Professional.where(CUSTOMER_ID: @prof_dept_affiliation.FROM_CUSTOMER_ID)[0]

        @department = Onepharma::Department.where(CUSTOMER_ID: @prof_dept_affiliation.TO_CUSTOMER_ID)[0]
        @dept_inst_affiliation = Onepharma::DeptInstAffiliation.where(FROM_CUSTOMER_ID: @department.CUSTOMER_ID)[0]

        @institution = Onepharma::Institution.where(CUSTOMER_ID: @dept_inst_affiliation.TO_CUSTOMER_ID)[0]
        @institution_departments_list_for_select = @institution.departments.pluck(:FULL_NAME, :CUSTOMER_ID)

        @institution_list_for_select = Onepharma::Institution.by_active.pluck(:FULL_NAME, :CUSTOMER_ID)

        render partial: "prof_dept_affiliations/edit_form"
    end

    def edit_through_institution
        @prof_dept_affiliation = Onepharma::ProfDeptAffiliation.where(AFFILIATION_ID: params[:id])[0]
        @professional = Onepharma::Professional.where(CUSTOMER_ID: @prof_dept_affiliation.FROM_CUSTOMER_ID)[0]

        @department = Onepharma::Department.where(CUSTOMER_ID: @prof_dept_affiliation.TO_CUSTOMER_ID)[0]
        @dept_inst_affiliation = Onepharma::DeptInstAffiliation.where(FROM_CUSTOMER_ID: @department.CUSTOMER_ID)[0]

        @institution = Onepharma::Institution.where(CUSTOMER_ID: @dept_inst_affiliation.TO_CUSTOMER_ID)[0]
        @institution_departments_list_for_select = @institution.departments.pluck(:FULL_NAME, :CUSTOMER_ID)

        @institution_list_for_select = Onepharma::Institution.by_active.pluck(:FULL_NAME, :CUSTOMER_ID)

        render partial: "prof_dept_affiliations/edit_through_institution_form"
    end

    def destroy
        @prof_dept_affiliation = Onepharma::ProfDeptAffiliation.where(AFFILIATION_ID: params[:id])[0]
        @professional =  Onepharma::Professional.where(CUSTOMER_ID: @prof_dept_affiliation.FROM_CUSTOMER_ID)[0]
        @departments_list_hash = @professional.departments.index_by(&:CUSTOMER_ID)

        @prof_dept_affiliation.destroy
        if @prof_dept_affiliation.destroyed?
            flash.now[:success] = I18n.t("alerts.records.prof_dept_affiliation_removed")
        end
    end

    def update

        @prof_dept_affiliation = Onepharma::ProfDeptAffiliation.where(AFFILIATION_ID: params[:id])[0]
        @professional = Onepharma::Professional.where(CUSTOMER_ID: @prof_dept_affiliation.FROM_CUSTOMER_ID)[0]

        @department = Onepharma::Department.where(CUSTOMER_ID: @prof_dept_affiliation.TO_CUSTOMER_ID)[0]
        @departments_list_hash = @professional.departments.index_by(&:CUSTOMER_ID)
        @dept_inst_affiliation = Onepharma::DeptInstAffiliation.where(FROM_CUSTOMER_ID: @department.CUSTOMER_ID)[0]
        @institution_list_for_select = Onepharma::Institution.by_active.pluck(:FULL_NAME, :CUSTOMER_ID)
        @institution = Onepharma::Institution.where(CUSTOMER_ID: @dept_inst_affiliation.TO_CUSTOMER_ID)[0]
        @institution_departments_list_for_select = @institution.departments.pluck(:FULL_NAME, :CUSTOMER_ID)

        if @prof_dept_affiliation.update(prof_dept_affiliation_params)
            flash.now[:success] = I18n.t("alerts.records.prof_dept_affiliation_updated")
        else
            flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
        end
    end

    def update_through_institution
        @prof_dept_affiliation = Onepharma::ProfDeptAffiliation.where(AFFILIATION_ID: params[:id])[0]
        @professional = Onepharma::Professional.where(CUSTOMER_ID: @prof_dept_affiliation.FROM_CUSTOMER_ID)[0]

        @department = Onepharma::Department.where(CUSTOMER_ID: @prof_dept_affiliation.TO_CUSTOMER_ID)[0]
        @departments_list_hash = @professional.departments.index_by(&:CUSTOMER_ID)
        @dept_inst_affiliation = Onepharma::DeptInstAffiliation.where(FROM_CUSTOMER_ID: @department.CUSTOMER_ID)[0]
        @institution_list_for_select = Onepharma::Institution.by_active.pluck(:FULL_NAME, :CUSTOMER_ID)
        @institution = Onepharma::Institution.where(CUSTOMER_ID: @dept_inst_affiliation.TO_CUSTOMER_ID)[0]
        @institution_departments_list_for_select = @institution.departments.pluck(:FULL_NAME, :CUSTOMER_ID)

        if @prof_dept_affiliation.update(prof_dept_affiliation_params)
            flash.now[:success] = I18n.t("alerts.records.prof_dept_affiliation_updated")
        else
            flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
        end
    end

    def get_institution_departments
        @institution = Onepharma::Institution.where(CUSTOMER_ID: params[:selected_value])[0]
        @professional = Onepharma::Professional.where(CUSTOMER_ID: params[:professional_id])[0]
        @new_prof_dept_affiliation = Onepharma::ProfDeptAffiliation.new(FROM_CUSTOMER_ID: @professional.CUSTOMER_ID)
        @institution_departments_list_for_select = @institution.departments.by_active.pluck(:FULL_NAME, :CUSTOMER_ID)
    end

    def institution_add_new_prof_dept_affiliation
        @specialties_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.specialty_tmp', EXCLUDE: nil).pluck :DESCRIPTION, :CODE

        @department = Onepharma::Department.where(CUSTOMER_ID: params[:department_id])[0]
        @institution = @department.institutions[0]

        @new_prof_dept_affiliation = Onepharma::ProfDeptAffiliation.new(TO_CUSTOMER_ID: @department.CUSTOMER_ID)

        render partial: "prof_dept_affiliations/modals/institution_add_new_prof_dept_affiliation"
    end

    private

    def prof_dept_affiliation_params
        #FROM_CUSTOMER_ID - :professional
        #TO_CUSTOMER_ID - :department
        params.require(:onepharma_prof_dept_affiliation).permit( :FROM_CUSTOMER_ID, :TO_CUSTOMER_ID, :AFFILIATION_ROLE_1, :COMPANY_DB_OWNER, :STATUS, :AFFILIATION_MAIN )
    end

    def get_lists
        #lista de cargos
        @affiliation_roles_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.affiliation_role').where(EXCLUDE: nil).order(:DESCRIPTION).pluck :DESCRIPTION, :CODE

        #lista deowners
        @affiliation_owners_list_for_select = OpcMaster::OpcCompany.where(company_id: [9, 20]).pluck :name, :company_id

        #hash de cargos
        @affiliation_roles_list_hash = @affiliation_roles_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }

        #hash de owners
        @affiliation_owners_list_hash = @affiliation_owners_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }
    end

end
