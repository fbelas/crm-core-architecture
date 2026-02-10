class DepartmentsController < BackofficeController
    before_action :require_institution
    before_action :get_type_lists

    layout "backoffice"

    def create
        @new_department = Onepharma::Department.create(department_params.merge(FIRST_NAME: @institution.FULL_NAME))
        if @new_department.valid?
            @new_affiliation = Onepharma::DeptInstAffiliation.create(FROM_CUSTOMER_ID: @new_department.CUSTOMER_ID, TO_CUSTOMER_ID: @institution.CUSTOMER_ID, TO_NAME: @institution.FULL_NAME)
            flash.now[:success] = I18n.t("alerts.records.department_created")
        else
            flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
        end
    end

    def edit
        @department = Onepharma::Department.where(CUSTOMER_ID: params[:id])[0]

        render partial: "departments/edit_form"
    end

    def update
        @department = Onepharma::Department.where(CUSTOMER_ID: params[:id])[0]

        if @department.update(department_params)
            #altera a affiliação consoante o estado do dpto, em caso de delete estão dependent
            @department.dept_inst_affiliations.update(STATUS: department_params[:STATUS])
            if department_params[:STATUS] != "ACTV"
                @department.prof_dept_affiliations.update(STATUS: department_params[:STATUS])
            end
            flash.now[:success] = I18n.t("alerts.records.department_updated")
        else

            flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
        end
    end

    def destroy
        @department = Onepharma::Department.where(CUSTOMER_ID: params[:id])[0]
        @department.destroy

        if @department.destroyed?
            @institution = Onepharma::Institution.where(CUSTOMER_ID: params[:institution_id])[0]
            flash.now[:success] = I18n.t("alerts.records.department_removed")
        end
    end

    private

    def department_params
        params.require(:onepharma_department).permit(:CUSTOMER_TYPE, :CUSTOMER_SUB_TYPE, :LAST_NAME, :STATUS )
    end

    def require_institution
        @institution = Onepharma::Institution.where(CUSTOMER_ID: params[:institution_id])[0]
        permission_denied if @institution.blank?
    end

    def get_type_lists
        @department_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'department.type', EXCLUDE: nil).map { |type| [type.DESCRIPTION, type.CODE] }
        @department_sub_type_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'department.sub_type', EXCLUDE: nil).map { |type| [type.DESCRIPTION, type.CODE] }

        @department_type_hash = @department_type_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }
        @department_sub_type_hash = @department_sub_type_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }
    end

end
