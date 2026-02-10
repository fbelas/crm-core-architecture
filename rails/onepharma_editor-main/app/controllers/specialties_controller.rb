class SpecialtiesController < BackofficeController
    before_action :require_professional
    before_action :get_lists

    layout "backoffice"

    def create
        @new_specialty = Onepharma::Specialty.create(specialty_params)
        @specialty = @new_specialty

        if @specialty.valid?
            flash.now[:success] = I18n.t("alerts.records.specialty_created")
            @new_specialty = Onepharma::Specialty.new
        else
            flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
        end
    end

    def edit
        @specialty = Onepharma::Specialty.where(CUSTOMER_SPECIALTY_ID: params[:id])[0]

        render partial: "specialties/edit_form"
    end

    def update
        @specialty = Onepharma::Specialty.where(CUSTOMER_SPECIALTY_ID: params[:id])[0]
        previous_rank = @specialty.SPECIALTY_RANK

        if @specialty.update(specialty_params)
            flash.now[:success] = I18n.t("alerts.records.contact_updated")
            @new_specialty = Onepharma::Specialty.new
        else
            flash.now[:error] = I18n.t("alerts.records.erro_check_the_fields")
        end
    end

    def destroy
        @specialty = Onepharma::Specialty.where(CUSTOMER_SPECIALTY_ID: params[:id])[0]
        @specialty.destroy

        if @specialty.destroyed?
            flash.now[:success] = I18n.t("alerts.records.specialty_removed")
            @new_specialty = Onepharma::Specialty.new
        end
    end

    private
    def specialty_params
        params.require(:onepharma_specialty).permit(:SPECIALTY, :SPECIALTY_RANK ).merge(CUSTOMER_ID: @professional.CUSTOMER_ID)
    end

    def require_professional
        @professional = Onepharma::Professional.where(CUSTOMER_ID: params[:professional_id])[0]
        permission_denied if @professional.blank?
    end

    def get_lists
        #lista de especialidades
        @specialties_list_for_select = Onepharma::TableOfValue.where(CODE_ROLE: 'person.specialty_tmp', EXCLUDE: nil).order(DESCRIPTION: :asc).pluck :DESCRIPTION, :CODE
        #hash de tipos e subtipos
        @specialties_list_hash = @specialties_list_for_select.each_with_object({}) { |sub_array, hash| hash[sub_array[1]] = sub_array[0] }
    end

end
